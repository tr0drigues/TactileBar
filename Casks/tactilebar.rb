cask "tactilebar" do
  version "1.3.1"
  sha256 :no_check

  url "https://github.com/tr0drigues/TactileBar/releases/download/v#{version}/TactileBar-macOS.dmg"
  name "TactileBar"
  desc "Precision Menu Bar Telemetry & Hardware-Inspired Command Deck for macOS"
  homepage "https://github.com/tr0drigues/TactileBar"

  depends_on macos: ">= :sonoma"

  app "TactileBar.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/TactileBar.app"]
  end

  zap trash: [
    "~/Library/Preferences/studio.tactile.TactileBar.plist",
  ]
end
