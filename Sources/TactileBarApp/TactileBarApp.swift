import AppKit
import SwiftUI
import SwitchCatalog
import TactileCore
import TactileRing
import TactileUI

@main
struct TactileBarApp: App {
    private let registry: SwitchRegistry
    private let ringController: RingController

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        NSApplication.shared.applicationIconImage = MenuBarTelemetryIcon.makeApplicationIconImage()
        let registry = SwitchRegistry(switches: TactileSwitchCatalog.makeAllSwitches())
        self.registry = registry
        self.ringController = RingController(registry: registry)
        ringController.start()
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
