#!/bin/bash

# This script is designed to be run from the root of the Git repository.

# --- Configuration ---
CASK_NAME="webcord"
REPO_OWNER="SpacingBat3"
REPO_NAME="WebCord"
OUTPUT_DIR="./Casks" # The output directory is relative to the script location
OUTPUT_FILE="${OUTPUT_DIR}/${CASK_NAME}.rb"
TEMP_DIR="/tmp/${CASK_NAME}_cask_build_$$"

# --- Prerequisites Check ---
# ... (You can keep your checks here, they are good practice) ...

echo "--- Generating Homebrew Cask for ${CASK_NAME} ---"
# ... (The entire middle of your script for fetching versions and checksums remains the same) ...

# --- [Copy the middle of your working script here] ---
# For brevity, I'm skipping the middle, but it should be identical to your last working version.
# Just ensure the final `cat << EOF > "$OUTPUT_FILE"` part is as below.
# --- [End of copied section] ---


# --- The rest of your script should look like this ---

echo "--- Writing Cask file to: ${OUTPUT_FILE} ---"

# --- Generate the Cask Ruby file content ---
APP_FILENAME="WebCord.app"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Create a bash variable that holds the literal string '#{version}'.
LITERAL_RUBY_VERSION_VAR='#{version}'

cat << EOF > "$OUTPUT_FILE"
cask "${CASK_NAME}" do
  version "${VERSION}"

  on_arm do
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
                   args: ["-cr", "\#{appdir}/#{APP_FILENAME}"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/WebCord",
    "~/Library/Preferences/com.electron.webcord.plist",
    "~/Library/Saved Application State/com.electron.webcord.savedState",
  ]
end
EOF

# --- Clean up temporary files ---
rm -rf "$TEMP_DIR"

echo "--- Cask Generation Complete! ---"