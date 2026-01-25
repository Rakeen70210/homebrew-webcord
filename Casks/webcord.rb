cask "webcord" do
  version "4.12.1"

  on_arm do
    # Use the pre-constructed literal variable. Bash will expand it to '#{version}'.
    url "https://github.com/SpacingBat3/WebCord/releases/download/v#{version}/WebCord.arm64.dmg"
    sha256 "eb00ecad646253f63a39482cb222389103d894866edb69b1d200b0f463fa1117"
  end
  on_intel do
    url "https://github.com/SpacingBat3/WebCord/releases/download/v#{version}/WebCord.x64.dmg"
    sha256 "b86adf7b229dd32c19832b52011dbf6a1368d8ffeea6782516761f7e51937e24"
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
