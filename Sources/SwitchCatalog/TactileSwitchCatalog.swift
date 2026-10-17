import AppKit
import Foundation
import Observation
import SystemAdapters
import TactileCore

@Observable
@MainActor
public final class ConfigurableTactileSwitch: TactileSwitchProtocol {
    public let id: String
    public let title: String
    public let domain: SwitchDomain
    public let sfSymbolName: String
    public let subsystemLabel: String
    public let isMomentaryAction: Bool
    public var state: SwitchExecutionState

    private let onTriggerHandler: @MainActor (ConfigurableTactileSwitch) async -> Void
    private let onRefreshHandler: @MainActor (ConfigurableTactileSwitch) async -> Void

    public init(
        id: String,
        title: String,
        domain: SwitchDomain,
        sfSymbolName: String,
        subsystemLabel: String,
        isMomentaryAction: Bool = false,
        initialState: SwitchExecutionState = .off(statusText: "STANDBY"),
        onTriggerHandler: @escaping @MainActor (ConfigurableTactileSwitch) async -> Void,
        onRefreshHandler: @escaping @MainActor (ConfigurableTactileSwitch) async -> Void = { _ in }
    ) {
        self.id = id
        self.title = title
        self.domain = domain
        self.sfSymbolName = sfSymbolName
        self.subsystemLabel = subsystemLabel
        self.isMomentaryAction = isMomentaryAction
        self.state = initialState
        self.onTriggerHandler = onTriggerHandler
        self.onRefreshHandler = onRefreshHandler
    }

    public func trigger() async {
        await onTriggerHandler(self)
    }

    public func refreshState() async {
        await onRefreshHandler(self)
    }
}

public enum TactileSwitchCatalog {
    @MainActor
    public static func makeAllSwitches() -> [any TactileSwitchProtocol] {
        let powerAdapter = PowerAssertionAdapter.shared
        let audioAdapter = CoreAudioAdapter.shared
        let workspaceAdapter = WorkspaceAutomationAdapter.shared
        let shieldController = ScreenCleanShieldController.shared

        return [
            // MARK: - M.01 POWER & SLEEP (5)
            ConfigurableTactileSwitch(
                id: "SW.01",
                title: "KEEP AWAKE",
                domain: .power,
                sfSymbolName: "cup.and.saucer.fill",
                subsystemLabel: "IOKit.pwr_mgt",
                initialState: .off(statusText: "ALLOW SLEEP"),
                onTriggerHandler: { item in
                    let target = !item.state.isEnabled
                    let ok = await powerAdapter.setKeepAwake(enabled: target)
                    if ok {
                        item.state = target ? .on(statusText: "AWAKE ACTIVE") : .off(statusText: "ALLOW SLEEP")
                    }
                },
                onRefreshHandler: { item in
                    let active = await powerAdapter.isKeepAwakeActive()
                    item.state = active ? .on(statusText: "AWAKE ACTIVE") : .off(statusText: "ALLOW SLEEP")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.02",
                title: "DISPLAY SLEEP",
                domain: .power,
                sfSymbolName: "display.trianglebadge.exclamationmark",
                subsystemLabel: "pmset displaysleepnow",
                isMomentaryAction: true,
                initialState: .off(statusText: "INSTANT TRIGGER"),
                onTriggerHandler: { item in
                    item.state = .busy(progressText: "SLEEPING...")
                    _ = await powerAdapter.triggerImmediateDisplaySleep()
                    item.state = .off(statusText: "INSTANT TRIGGER")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.03",
                title: "SCREEN SAVER",
                domain: .power,
                sfSymbolName: "sparkles.tv",
                subsystemLabel: "ScreenSaverEngine",
                isMomentaryAction: true,
                initialState: .off(statusText: "LAUNCH ENGINE"),
                onTriggerHandler: { item in
                    _ = await workspaceAdapter.launchScreenSaver()
                    item.state = .off(statusText: "LAUNCHED")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.04",
                title: "LOW POWER MODE",
                domain: .power,
                sfSymbolName: "battery.50",
                subsystemLabel: "pmset lowpowermode",
                initialState: .off(statusText: "NORMAL POWER"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    if powerAdapter.setLowPowerModeWithAdminPrompt(enabled: next) {
                        item.state = next ? .on(statusText: "BATTERY SAVER") : .off(statusText: "NORMAL POWER")
                    }
                },
                onRefreshHandler: { item in
                    let active = await powerAdapter.readLowPowerModeEnabled()
                    item.state = active ? .on(statusText: "BATTERY SAVER") : .off(statusText: "NORMAL POWER")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.05",
                title: "ENERGY MODE",
                domain: .power,
                sfSymbolName: "gauge.with.dots.needle.67percent",
                subsystemLabel: "Thermal / Power Profile",
                initialState: .off(statusText: "AUTOMATIC"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    item.state = next ? .on(statusText: "HIGH OUTPUT") : .off(statusText: "AUTOMATIC")
                }
            ),

            // MARK: - M.02 OPTICS & DISPLAY (4)
            ConfigurableTactileSwitch(
                id: "SW.06",
                title: "DARK MODE",
                domain: .optics,
                sfSymbolName: "circle.lefthalf.filled",
                subsystemLabel: "System Events / Theme",
                initialState: .on(statusText: "OBSIDIAN DARK"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    if workspaceAdapter.setDarkMode(enabled: next) {
                        item.state = next ? .on(statusText: "OBSIDIAN DARK") : .off(statusText: "DAYLIGHT")
                    }
                },
                onRefreshHandler: { item in
                    let isDark = await workspaceAdapter.isDarkModeEnabled()
                    item.state = isDark ? .on(statusText: "OBSIDIAN DARK") : .off(statusText: "DAYLIGHT")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.07",
                title: "NIGHT SHIFT",
                domain: .optics,
                sfSymbolName: "sun.max.trianglebadge.exclamationmark",
                subsystemLabel: "CoreBrightness Kelvin",
                initialState: .off(statusText: "6500K NEUTRAL"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    item.state = next ? .on(statusText: "3400K WARM") : .off(statusText: "6500K NEUTRAL")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.08",
                title: "TRUE TONE",
                domain: .optics,
                sfSymbolName: "rays",
                subsystemLabel: "Ambient Chromatic Sensor",
                initialState: .on(statusText: "SENSOR ADAPT"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    item.state = next ? .on(statusText: "SENSOR ADAPT") : .off(statusText: "FIXED WHITE")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.09",
                title: "RESOLUTION",
                domain: .optics,
                sfSymbolName: "aspectratio",
                subsystemLabel: "CGDisplayMode HiDPI",
                initialState: .on(statusText: "NATIVE HIDPI 2X"),
                onTriggerHandler: { item in
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                    item.state = .on(statusText: "NATIVE HIDPI 2X")
                }
            ),

            // MARK: - M.03 SPATIAL WORKSPACE (6)
            ConfigurableTactileSwitch(
                id: "SW.10",
                title: "HIDE DESKTOP",
                domain: .workspace,
                sfSymbolName: "menubar.dock.rectangle.badge.record",
                subsystemLabel: "com.apple.finder",
                initialState: .off(statusText: "ICONS VISIBLE"),
                onTriggerHandler: { item in
                    let shouldHide = !item.state.isEnabled
                    let ok = await workspaceAdapter.writeDefaultsBool(
                        domain: "com.apple.finder",
                        key: "CreateDesktop",
                        value: !shouldHide,
                        restartProcess: "Finder"
                    )
                    if ok {
                        item.state = shouldHide ? .on(statusText: "ICONS HIDDEN") : .off(statusText: "ICONS VISIBLE")
                    }
                },
                onRefreshHandler: { item in
                    let createDesktop = await workspaceAdapter.readDefaultsBool(
                        domain: "com.apple.finder",
                        key: "CreateDesktop",
                        defaultValue: true
                    )
                    item.state = createDesktop ? .off(statusText: "ICONS VISIBLE") : .on(statusText: "ICONS HIDDEN")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.11",
                title: "HIDDEN FILES",
                domain: .workspace,
                sfSymbolName: "eye.square",
                subsystemLabel: "AppleShowAllFiles",
                initialState: .off(statusText: "DOTFILES MASKED"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    let ok = await workspaceAdapter.writeDefaultsBool(
                        domain: "com.apple.finder",
                        key: "AppleShowAllFiles",
                        value: next,
                        restartProcess: "Finder"
                    )
                    if ok {
                        item.state = next ? .on(statusText: "DOTFILES SHOWN") : .off(statusText: "DOTFILES MASKED")
                    }
                },
                onRefreshHandler: { item in
                    let shown = await workspaceAdapter.readDefaultsBool(
                        domain: "com.apple.finder",
                        key: "AppleShowAllFiles",
                        defaultValue: false
                    )
                    item.state = shown ? .on(statusText: "DOTFILES SHOWN") : .off(statusText: "DOTFILES MASKED")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.12",
                title: "HIDE DOCK",
                domain: .workspace,
                sfSymbolName: "dock.arrow.down.rectangle",
                subsystemLabel: "com.apple.dock autohide",
                initialState: .off(statusText: "DOCK PINNED"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    let ok = await workspaceAdapter.writeDefaultsBool(
                        domain: "com.apple.dock",
                        key: "autohide",
                        value: next,
                        restartProcess: "Dock"
                    )
                    if ok {
                        item.state = next ? .on(statusText: "AUTOHIDE ON") : .off(statusText: "DOCK PINNED")
                    }
                },
                onRefreshHandler: { item in
                    let auto = await workspaceAdapter.readDefaultsBool(
                        domain: "com.apple.dock",
                        key: "autohide",
                        defaultValue: false
                    )
                    item.state = auto ? .on(statusText: "AUTOHIDE ON") : .off(statusText: "DOCK PINNED")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.13",
                title: "HIDE WINDOWS",
                domain: .workspace,
                sfSymbolName: "macwindow.on.rectangle",
                subsystemLabel: "NSWorkspace.hideOthers",
                isMomentaryAction: true,
                initialState: .off(statusText: "CLEAR STAGE"),
                onTriggerHandler: { item in
                    workspaceAdapter.hideAllOtherApplications()
                    item.state = .off(statusText: "WINDOWS HIDDEN")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.14",
                title: "STAGE MANAGER",
                domain: .workspace,
                sfSymbolName: "squares.leading.rectangle",
                subsystemLabel: "com.apple.WindowManager",
                initialState: .off(statusText: "DISABLED"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    let ok = await workspaceAdapter.writeDefaultsBool(
                        domain: "com.apple.WindowManager",
                        key: "GloballyEnabled",
                        value: next
                    )
                    if ok {
                        item.state = next ? .on(statusText: "STAGE ACTIVE") : .off(statusText: "DISABLED")
                    }
                },
                onRefreshHandler: { item in
                    let active = await workspaceAdapter.readDefaultsBool(
                        domain: "com.apple.WindowManager",
                        key: "GloballyEnabled",
                        defaultValue: false
                    )
                    item.state = active ? .on(statusText: "STAGE ACTIVE") : .off(statusText: "DISABLED")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.15",
                title: "HIDE WIDGETS",
                domain: .workspace,
                sfSymbolName: "rectangle.grid.2x2",
                subsystemLabel: "StandardHideWidgets",
                initialState: .off(statusText: "WIDGETS SHOWN"),
                onTriggerHandler: { item in
                    let hideWidgets = !item.state.isEnabled
                    let ok = await workspaceAdapter.writeDefaultsBool(
                        domain: "com.apple.WindowManager",
                        key: "StandardHideWidgets",
                        value: hideWidgets
                    )
                    if ok {
                        item.state = hideWidgets ? .on(statusText: "WIDGETS HIDDEN") : .off(statusText: "WIDGETS SHOWN")
                    }
                },
                onRefreshHandler: { item in
                    let hidden = await workspaceAdapter.readDefaultsBool(
                        domain: "com.apple.WindowManager",
                        key: "StandardHideWidgets",
                        defaultValue: false
                    )
                    item.state = hidden ? .on(statusText: "WIDGETS HIDDEN") : .off(statusText: "WIDGETS SHOWN")
                }
            ),

            // MARK: - M.04 ACOUSTIC & RF SIGNAL (3)
            ConfigurableTactileSwitch(
                id: "SW.16",
                title: "MUTE MIC",
                domain: .signal,
                sfSymbolName: "mic.slash.fill",
                subsystemLabel: "CoreAudio InputMute",
                initialState: .off(statusText: "INPUT LIVE"),
                onTriggerHandler: { item in
                    let muteNext = !item.state.isEnabled
                    let ok = await audioAdapter.setDefaultInputMuted(muteNext)
                    if ok {
                        item.state = muteNext ? .on(statusText: "MIC CLAMPED") : .off(statusText: "INPUT LIVE")
                    }
                },
                onRefreshHandler: { item in
                    let muted = await audioAdapter.isDefaultInputMuted()
                    item.state = muted ? .on(statusText: "MIC CLAMPED") : .off(statusText: "INPUT LIVE")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.17",
                title: "BT AUDIO LINK",
                domain: .signal,
                sfSymbolName: "headphones",
                subsystemLabel: "IOBluetooth Audio/RF",
                initialState: .off(statusText: "PAIRED STANDBY"),
                onTriggerHandler: { item in
                    let devices = BluetoothDeviceService.listPairedDevices()
                    let preferredID = UserDefaults.standard.string(forKey: SwitchRegistry.preferredBluetoothStorageKey) ?? ""
                    guard let target = devices.first(where: { $0.id == preferredID }) ?? devices.first else {
                        NSWorkspace.shared.open(AppConfiguration.SystemPreferenceURLs.bluetoothPrivacy)
                        item.state = .off(statusText: "NO PAIRED BT")
                        return
                    }
                    let shouldConnect = !target.isConnected
                    item.state = .busy(progressText: shouldConnect ? "LINKING \(target.name.uppercased())..." : "DISCONNECTING...")
                    let ok = await BluetoothDeviceService.setConnection(address: target.address, connect: shouldConnect)
                    let updated = BluetoothDeviceService.listPairedDevices().first(where: { $0.id == target.id })
                    let isNowConnected = updated?.isConnected ?? (ok ? shouldConnect : target.isConnected)
                    item.state = isNowConnected
                        ? .on(statusText: "\(target.name.uppercased()) · ON")
                        : .off(statusText: "\(target.name.uppercased()) · OFF")
                },
                onRefreshHandler: { item in
                    let devices = BluetoothDeviceService.listPairedDevices()
                    let preferredID = UserDefaults.standard.string(forKey: SwitchRegistry.preferredBluetoothStorageKey) ?? ""
                    if let connected = devices.first(where: { $0.isConnected }) {
                        item.state = .on(statusText: "\(connected.name.uppercased()) · ON")
                    } else if let target = devices.first(where: { $0.id == preferredID }) ?? devices.first {
                        item.state = .off(statusText: "\(target.name.uppercased()) · OFF")
                    } else {
                        item.state = .off(statusText: "NO PAIRED BT")
                    }
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.18",
                title: "PLAY MUSIC",
                domain: .signal,
                sfSymbolName: "waveform",
                subsystemLabel: "Music / Spotify Bridge",
                isMomentaryAction: true,
                initialState: .off(statusText: "PLAY / PAUSE"),
                onTriggerHandler: { item in
                    _ = workspaceAdapter.toggleMusicPlayback()
                    item.state = .off(statusText: "SIGNAL SENT")
                }
            ),

            // MARK: - M.05 SECURITY & PURGE (8)
            ConfigurableTactileSwitch(
                id: "SW.19",
                title: "SCREEN CLEAN",
                domain: .security,
                sfSymbolName: "sparkles.rectangle.stack.fill",
                subsystemLabel: "NSWindow .screenSaver",
                initialState: .off(statusText: "SHIELD STANDBY"),
                onTriggerHandler: { item in
                    let next = !shieldController.isScreenCleanActive
                    shieldController.setScreenCleanMode(enabled: next)
                    item.state = next ? .on(statusText: "SHIELD LOCKED") : .off(statusText: "SHIELD STANDBY")
                },
                onRefreshHandler: { item in
                    let active = shieldController.isScreenCleanActive
                    item.state = active ? .on(statusText: "SHIELD LOCKED") : .off(statusText: "SHIELD STANDBY")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.20",
                title: "LOCK KEYBOARD",
                domain: .security,
                sfSymbolName: "keyboard.badge.ellipsis",
                subsystemLabel: "NSEvent LocalShield",
                initialState: .off(statusText: "KEYS UNLOCKED"),
                onTriggerHandler: { item in
                    let next = !shieldController.isKeyboardLocked
                    shieldController.setKeyboardLock(enabled: next)
                    item.state = next ? .on(statusText: "KEYS LOCKED") : .off(statusText: "KEYS UNLOCKED")
                },
                onRefreshHandler: { item in
                    let active = shieldController.isKeyboardLocked
                    item.state = active ? .on(statusText: "KEYS LOCKED") : .off(statusText: "KEYS UNLOCKED")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.21",
                title: "LOCK SCREEN",
                domain: .security,
                sfSymbolName: "lock.display",
                subsystemLabel: "Cmd+Ctrl+Q Session",
                isMomentaryAction: true,
                initialState: .off(statusText: "INSTANT LOCK"),
                onTriggerHandler: { item in
                    _ = workspaceAdapter.lockScreenImmediate()
                    item.state = .off(statusText: "SESSION LOCKED")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.22",
                title: "EMPTY TRASH",
                domain: .security,
                sfSymbolName: "trash.slash.fill",
                subsystemLabel: "Finder EmptyTrash",
                isMomentaryAction: true,
                initialState: .off(statusText: "PURGE BIN"),
                onTriggerHandler: { item in
                    item.state = .busy(progressText: "PURGING...")
                    _ = workspaceAdapter.emptySystemTrash()
                    item.state = .off(statusText: "TRASH EMPTY")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.23",
                title: "PASTEBOARD",
                domain: .security,
                sfSymbolName: "doc.on.clipboard",
                subsystemLabel: "NSPasteboard.general",
                isMomentaryAction: true,
                initialState: .off(statusText: "CLEAR BUFFER"),
                onTriggerHandler: { item in
                    _ = workspaceAdapter.clearGeneralPasteboard()
                    item.state = .off(statusText: "BUFFER ZEROED")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.24",
                title: "EJECT DISKS",
                domain: .security,
                sfSymbolName: "eject.circle.fill",
                subsystemLabel: "DiskArbitration",
                isMomentaryAction: true,
                initialState: .off(statusText: "UNMOUNT ALL"),
                onTriggerHandler: { item in
                    item.state = .busy(progressText: "UNMOUNTING...")
                    let count = await workspaceAdapter.ejectRemovableVolumes()
                    item.state = .off(statusText: "EJECTED: \(count)")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.25",
                title: "XCODE CLEAN",
                domain: .security,
                sfSymbolName: "hammer.circle.fill",
                subsystemLabel: "DerivedData Purge",
                isMomentaryAction: true,
                initialState: .off(statusText: "SCANNING..."),
                onTriggerHandler: { item in
                    item.state = .busy(progressText: "PURGING...")
                    let ok = await workspaceAdapter.purgeXcodeDerivedData()
                    item.state = .off(statusText: ok ? "ZERO (CLEAN)" : "PURGE FAILED")
                },
                onRefreshHandler: { item in
                    let formattedSize = await workspaceAdapter.calculateXcodeDerivedDataSizeFormatted()
                    item.state = .off(statusText: "CACHE: \(formattedSize)")
                }
            ),
            ConfigurableTactileSwitch(
                id: "SW.26",
                title: "DO NOT DISTURB",
                domain: .security,
                sfSymbolName: "moon.zzz.fill",
                subsystemLabel: "Focus / Notifications",
                initialState: .off(statusText: "ALERTS ALLOWED"),
                onTriggerHandler: { item in
                    let next = !item.state.isEnabled
                    item.state = next ? .on(statusText: "SILENCE ACTIVE") : .off(statusText: "ALERTS ALLOWED")
                }
            )
        ]
    }
}
