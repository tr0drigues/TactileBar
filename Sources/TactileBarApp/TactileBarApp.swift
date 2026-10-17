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
    }

    var body: some Scene {
        MenuBarExtra {
            MainPopoverView(registry: registry)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.2.square.on.square")
                if registry.activeSwitchCount > 0 {
                    Text("\(registry.activeSwitchCount)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
