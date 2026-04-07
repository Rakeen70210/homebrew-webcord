cask "webcord" do
  version "4.13.0"

  on_arm do
    # Use the pre-constructed literal variable. Bash will expand it to '#{version}'.
    url "https://github.com/SpacingBat3/WebCord/releases/download/v#{version}/WebCord.arm64.dmg"
    sha256 "9f05de979c983380a56b5d82c08a4c0a9dd43e5e75de0ea325a6d2e3510dced9"
  end
  on_intel do
    url "https://github.com/SpacingBat3/WebCord/releases/download/v#{version}/WebCord.x64.dmg"
    sha256 "cbc42877b44f728fe0d9a3872413ecf05c65c50bfb24c955ed8ee7bb3ee94112"
  end

  name "WebCord"
  desc "A Discord client implemented without Discord API"
  homepage "https://github.com/SpacingBat3/WebCord"

  app "WebCord.app"

  livecheck do
    url :url
    strategy :github_latest
  end

  postflight do
    system_command "xattr",
                   args: ["-cr", "#{appdir}/WebCord.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/WebCord",
    "~/Library/Preferences/com.electron.webcord.plist",
    "~/Library/Saved Application State/com.electron.webcord.savedState",
  ]
end
