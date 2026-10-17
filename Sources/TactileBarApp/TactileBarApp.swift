import AppKit
import SwiftUI
import SwitchCatalog
import TactileCore
import TactileUI

@main
struct TactileBarApp: App {
    private let registry = SwitchRegistry(
        switches: TactileSwitchCatalog.makeAllSwitches()
    )

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        NSApplication.shared.applicationIconImage = MenuBarTelemetryIcon.makeApplicationIconImage()
    }

    var body: some Scene {
        MenuBarExtra {
            MainPopoverView(registry: registry)
        } label: {
            Image(nsImage: MenuBarTelemetryIcon.makeStatusBarImage(activeCount: registry.activeSwitchCount))
        }
        .menuBarExtraStyle(.window)
    }
}
