import Foundation
import Observation

/// Preferências do anel radial, compartilhadas entre o popover e o controlador do anel.
@Observable
@MainActor
public final class RingPreferences {
    public static let enabledStorageKey = "studio.tactile.TactileBar.ring.enabled"

    /// Atalho padrão exibido na interface (⌃⌥Space).
    public static let hotKeyLabel = "⌃⌥SPACE"

    /// Switches que apagam ou desmontam algo: exigem armar antes de disparar pelo anel.
    public static let destructiveSwitchIDs: Set<String> = [
        "SW.22", // EMPTY TRASH
        "SW.23", // PASTEBOARD
        "SW.24", // EJECT DISKS
        "SW.25"  // XCODE CLEAN
    ]

    public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            userDefaults.set(isEnabled, forKey: Self.enabledStorageKey)
            onChange?()
        }
    }

    public let timing: RingTiming

    @ObservationIgnored public var onChange: (@MainActor () -> Void)?
    @ObservationIgnored private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard, timing: RingTiming = .standard) {
        self.userDefaults = userDefaults
        self.timing = timing
        self.isEnabled = userDefaults.bool(forKey: Self.enabledStorageKey)
    }

    public static func isDestructive(_ switchID: String) -> Bool {
        destructiveSwitchIDs.contains(switchID)
    }
}
