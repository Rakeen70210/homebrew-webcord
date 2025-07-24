cask "webcord" do
  version ""

  on_arm do
    url "https://github.com/SpacingBat3/WebCord/releases/download/v#{version}/WebCord-#{version}-arm64.dmg"
    sha256 ""
  end
  on_intel do
    url "https://github.com/SpacingBat3/WebCord/releases/download/v#{version}/WebCord-#{version}-x64.dmg"
    sha256 ""
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
                   args: ["-cr", "\#{appdir}/#{APP_FILENAME}"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/WebCord",
    "~/Library/Preferences/com.electron.webcord.plist",
    "~/Library/Saved Application State/com.electron.webcord.savedState",
  ]
end
