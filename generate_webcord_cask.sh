#!/bin/bash

set -euo pipefail

# --- Configuration ---
CASK_NAME="webcord"
REPO_OWNER="SpacingBat3"
REPO_NAME="WebCord"
OUTPUT_DIR="./Casks" # The output directory is relative to the script location
OUTPUT_FILE="${OUTPUT_DIR}/${CASK_NAME}.rb"
TEMP_DIR="/tmp/${CASK_NAME}_cask_build_$$"

echo "--- Generating Homebrew Cask for ${CASK_NAME} ---"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: 'jq' is required but was not found in PATH."
  exit 1
fi

# --- 1. Fetch Latest Version from GitHub API ---
# Use an auth token if provided by the environment (for GitHub Actions)
CURL_ARGS=(-s -L)
if [ -n "${GH_TOKEN:-}" ]; then
  CURL_ARGS+=(-H "Authorization: Bearer ${GH_TOKEN}")
fi

echo "Fetching latest release information from GitHub API..."
LATEST_RELEASE_JSON=$(curl "${CURL_ARGS[@]}" "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest")

TAG_NAME=$(echo "$LATEST_RELEASE_JSON" | jq -r '.tag_name')
API_MESSAGE=$(echo "$LATEST_RELEASE_JSON" | jq -r '.message // empty')

# --- THIS IS THE CRUCIAL ERROR HANDLING ---
# If jq returns "null" or an empty string, exit with an error.
if [ "$TAG_NAME" == "null" ] || [ -z "$TAG_NAME" ]; then
  echo "Error: Failed to get a valid tag name from GitHub API."
  if [ -n "$API_MESSAGE" ]; then
    echo "API Message: $API_MESSAGE"
  fi
  echo "API Response: $LATEST_RELEASE_JSON"
  exit 1
fi

VERSION=$(echo "$TAG_NAME" | sed 's/^v//')
echo "Latest WebCord version detected: $VERSION (from tag: $TAG_NAME)"

# --- 2. Download and Calculate Checksums ---
# (Using a temporary directory for cleanliness)
TEMP_DIR="/tmp/${CASK_NAME}_cask_build_$$"
mkdir -p "$TEMP_DIR"
CHECKSUM_ARM64=""
CHECKSUM_X64=""
DMG_FILENAME_ARM64=""
DMG_FILENAME_X64=""
ARCHITECTURES=("arm64" "x64")

get_release_asset_tsv() {
  local name_regex="$1"
  echo "$LATEST_RELEASE_JSON" | jq -r --arg re "$name_regex" '
    .assets
    | map(select(.name | test($re; "i")))
    | map(select(.name | test("\\.dmg$"; "i")))
    | first
    | if . then [.name, .browser_download_url] | @tsv else empty end
  '
}

dump_asset_names() {
  echo "$LATEST_RELEASE_JSON" | jq -r '(.assets // [])[].name' | sed 's/^/  - /'
}

for ARCH in "${ARCHITECTURES[@]}"; do
    ASSET_REGEX=""
    if [ "$ARCH" == "arm64" ]; then ASSET_REGEX="arm64|aarch64"; fi
    if [ "$ARCH" == "x64" ]; then ASSET_REGEX="x64|x86_64|amd64|intel"; fi

    ASSET_TSV="$(get_release_asset_tsv "$ASSET_REGEX")"
    if [ -z "$ASSET_TSV" ]; then
        echo "Error: Could not find a .dmg release asset matching arch '${ARCH}' (regex: ${ASSET_REGEX})."
        echo "Available assets:"
        dump_asset_names
        exit 1
    fi

    DMG_FILENAME="$(echo "$ASSET_TSV" | cut -f1)"
    DOWNLOAD_URL="$(echo "$ASSET_TSV" | cut -f2)"
    TEMP_PATH="${TEMP_DIR}/${DMG_FILENAME}"
    echo "Downloading ${DMG_FILENAME}..."
    curl -fL --progress-bar -o "$TEMP_PATH" "$DOWNLOAD_URL"
    echo "Calculating SHA256 for ${DMG_FILENAME}..."
    LOCAL_SHA256=$(shasum -a 256 "$TEMP_PATH" | awk '{print $1}')
    if [ "$ARCH" == "arm64" ]; then
      CHECKSUM_ARM64="$LOCAL_SHA256"
      DMG_FILENAME_ARM64="$DMG_FILENAME"
    fi
    if [ "$ARCH" == "x64" ]; then
      CHECKSUM_X64="$LOCAL_SHA256"
      DMG_FILENAME_X64="$DMG_FILENAME"
    fi
done

if [ -z "$CHECKSUM_ARM64" ] || [ -z "$CHECKSUM_X64" ]; then
  echo "Error: Failed to compute checksums for one or more architectures."
  exit 1
fi

if [ -z "$DMG_FILENAME_ARM64" ] || [ -z "$DMG_FILENAME_X64" ]; then
  echo "Error: Failed to determine .dmg filenames for one or more architectures."
  exit 1
fi

echo "--- Writing Cask file to: ${OUTPUT_FILE} ---"
mkdir -p "$OUTPUT_DIR"

# --- 4. Generate the Cask Ruby file content ---
APP_FILENAME="WebCord.app"

# THIS IS THE CRUCIAL FIX:
# Create a bash variable that holds the literal string '#{version}'.
LITERAL_RUBY_VERSION_VAR='#{version}'
LITERAL_RUBY_APPDIR_VAR='#{appdir}'
LITERAL_RUBY_TAG_VAR="${LITERAL_RUBY_VERSION_VAR}"
if [[ "$TAG_NAME" == v* ]]; then
  LITERAL_RUBY_TAG_VAR="v${LITERAL_RUBY_VERSION_VAR}"
fi

cat << EOF > "$OUTPUT_FILE"
cask "${CASK_NAME}" do
  version "${VERSION}"

  on_arm do
    # Use the pre-constructed literal variable. Bash will expand it to '#{version}'.
    url "https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${LITERAL_RUBY_TAG_VAR}/${DMG_FILENAME_ARM64}"
    sha256 "${CHECKSUM_ARM64}"
  end
  on_intel do
    url "https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${LITERAL_RUBY_TAG_VAR}/${DMG_FILENAME_X64}"
    sha256 "${CHECKSUM_X64}"
  end

  name "WebCord"
  desc "A Discord client implemented without Discord API"
  homepage "https://github.com/${REPO_OWNER}/${REPO_NAME}"

  app "${APP_FILENAME}"

  livecheck do
    url :url
    strategy :github_latest
  end

  postflight do
    system_command "xattr",
                   args: ["-cr", "${LITERAL_RUBY_APPDIR_VAR}/WebCord.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/WebCord",
    "~/Library/Preferences/com.electron.webcord.plist",
    "~/Library/Saved Application State/com.electron.webcord.savedState",
  ]
end
EOF

# --- 5. Clean up temporary files ---
rm -rf "$TEMP_DIR"

echo "--- Cask Generation Complete! ---"
