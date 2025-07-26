#!/bin/bash

# --- Configuration ---
CASK_NAME="webcord"
REPO_OWNER="SpacingBat3"
REPO_NAME="WebCord"
OUTPUT_DIR="./Casks" # The output directory is relative to the script location
OUTPUT_FILE="${OUTPUT_DIR}/${CASK_NAME}.rb"
TEMP_DIR="/tmp/${CASK_NAME}_cask_build_$$"

# --- Prerequisites Check ---
# (Skipping for brevity, assuming they are installed from previous steps)

echo "--- Generating Homebrew Cask for ${CASK_NAME} ---"

# --- 1. Fetch Latest Version from GitHub API ---
LATEST_RELEASE_JSON=$(curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest")
TAG_NAME=$(echo "$LATEST_RELEASE_JSON" | jq -r '.tag_name')
VERSION=$(echo "$TAG_NAME" | sed 's/^v//')
echo "Latest WebCord version detected: $VERSION (from tag: $TAG_NAME)"

# --- 2. Download and Calculate Checksums ---
# (Using a temporary directory for cleanliness)
TEMP_DIR="/tmp/${CASK_NAME}_cask_build_$$"
mkdir -p "$TEMP_DIR"
CHECKSUM_ARM64=""
CHECKSUM_X64=""
ARCHITECTURES=("arm64" "x64")

for ARCH in "${ARCHITECTURES[@]}"; do
    DMG_FILENAME="WebCord-${VERSION}-${ARCH}.dmg"
    DOWNLOAD_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${TAG_NAME}/${DMG_FILENAME}"
    TEMP_PATH="${TEMP_DIR}/${DMG_FILENAME}"
    echo "Downloading ${DMG_FILENAME}..."
    curl -L --progress-bar -o "$TEMP_PATH" "$DOWNLOAD_URL"
    if [ ! -f "$TEMP_PATH" ]; then
        echo "Warning: Download failed for ${DMG_FILENAME}."
        continue
    fi
    echo "Calculating SHA256 for ${DMG_FILENAME}..."
    LOCAL_SHA256=$(shasum -a 256 "$TEMP_PATH" | awk '{print $1}')
    if [ "$ARCH" == "arm64" ]; then CHECKSUM_ARM64="$LOCAL_SHA256"; fi
    if [ "$ARCH" == "x64" ]; then CHECKSUM_X64="$LOCAL_SHA256"; fi
done

echo "--- Writing Cask file to: ${OUTPUT_FILE} ---"

# --- 4. Generate the Cask Ruby file content ---
APP_FILENAME="WebCord.app"

# THIS IS THE CRUCIAL FIX:
# Create a bash variable that holds the literal string '#{version}'.
LITERAL_RUBY_VERSION_VAR='#{version}'
LITERAL_RUBY_APPDIR_VAR='#{appdir}'

cat << EOF > "$OUTPUT_FILE"
cask "${CASK_NAME}" do
  version "${VERSION}"

  on_arm do
    # Use the pre-constructed literal variable. Bash will expand it to '#{version}'.
    url "https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/v${LITERAL_RUBY_VERSION_VAR}/WebCord-${LITERAL_RUBY_VERSION_VAR}-arm64.dmg"
    sha256 "${CHECKSUM_ARM64}"
  end
  on_intel do
    url "https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/v${LITERAL_RUBY_VERSION_VAR}/WebCord-${LITERAL_RUBY_VERSION_VAR}-x64.dmg"
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
