cask "webcord" do
  version "4.11.1"

  on_arm do
    # Use the pre-constructed literal variable. Bash will expand it to '#{version}'.
    url "https://github.com/SpacingBat3/WebCord/releases/download/v#{version}/WebCord-#{version}-arm64.dmg"
    sha256 "192bf1703b3ee6a52f082a01ff577df2902db53b362bd73323fa81bcb46f6e85"
  end
  on_intel do
    url "https://github.com/SpacingBat3/WebCord/releases/download/v#{version}/WebCord-#{version}-x64.dmg"
    sha256 "e2ea8a201ddf8373bb20976cea894be5d27e25f27d758bce07debfd0f30d984a"
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
