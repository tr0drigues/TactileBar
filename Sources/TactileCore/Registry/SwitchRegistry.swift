import Foundation
import Observation

@Observable
@MainActor
public final class SwitchRegistry {
    public private(set) var switches: [any TactileSwitchProtocol]
    public var selectedDomainFilter: SwitchDomain? = .power {
        didSet {
            isShowingPinnedOnly = false
        }
    }
    public var isShowingPinnedOnly: Bool = true
    public private(set) var pinnedSwitchIDs: Set<String>
    public var searchQuery: String = ""
    public var isShowingSupportSheet: Bool = false
    public var isShowingRadialDial: Bool = true
    public var availableUpdate: ReleaseUpdateInfo?
    public private(set) var mountedVolumes: [MountedVolumeInfo] = []
    public var selectedVolumeID: String = "/"
    public var isShowingVolumeList: Bool = false
    public private(set) var pairedBluetoothDevices: [BluetoothDeviceItem] = []
    public var selectedBluetoothDeviceID: String = "" {
        didSet {
            userDefaults.set(selectedBluetoothDeviceID, forKey: Self.preferredBluetoothStorageKey)
        }
    }
    public var isShowingBluetoothList: Bool = false
    public private(set) var connectingBluetoothDeviceID: String?
    public private(set) var totalTriggerCount: Int
    public private(set) var hardwareTelemetry: SystemHardwareTelemetrySnapshot = .initial

    public static let defaultPinnedSwitchIDs: [String] = [
        "SW.01", "SW.06", "SW.10", "SW.16", "SW.17", "SW.25"
    ]
    public static let preferredBluetoothStorageKey = "studio.tactile.TactileBar.preferredBluetoothAddress"
    public static let pinnedSwitchesStorageKey = "studio.tactile.TactileBar.pinnedSwitchIDs"
    private let triggerCountStorageKey = "studio.tactile.TactileBar.totalTriggerCount"
    private let userDefaults: UserDefaults

    public init(
        switches: [any TactileSwitchProtocol],
        userDefaults: UserDefaults = .standard
    ) {
        self.switches = switches
        self.userDefaults = userDefaults
        self.totalTriggerCount = userDefaults.integer(forKey: triggerCountStorageKey)
        if let savedPins = userDefaults.stringArray(forKey: Self.pinnedSwitchesStorageKey) {
            self.pinnedSwitchIDs = Set(savedPins)
        } else {
            self.pinnedSwitchIDs = Set(Self.defaultPinnedSwitchIDs)
        }
        self.hardwareTelemetry = HardwareTelemetryService.shared.captureSnapshot()
        let initialVolumes = DiskVolumeTelemetryService.listMountedVolumes()
        self.mountedVolumes = initialVolumes
        if let first = initialVolumes.first {
            self.selectedVolumeID = first.id
        }

        let initialBT = BluetoothDeviceService.listPairedDevices()
        self.pairedBluetoothDevices = initialBT
        let savedBT = userDefaults.string(forKey: Self.preferredBluetoothStorageKey) ?? ""
        if initialBT.contains(where: { $0.id == savedBT }) {
            self.selectedBluetoothDeviceID = savedBT
        } else if let firstBT = initialBT.first {
            self.selectedBluetoothDeviceID = firstBT.id
        }
    }

    public var selectedVolume: MountedVolumeInfo? {
        if let match = mountedVolumes.first(where: { $0.id == selectedVolumeID }) {
            return match
        }
        return mountedVolumes.first
    }

    public var ejectableVolumeCount: Int {
        mountedVolumes.filter(\.isEjectable).count
    }

    public var filteredSwitches: [any TactileSwitchProtocol] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            return switches.filter { item in
                item.title.localizedStandardContains(trimmedQuery)
                    || item.id.localizedStandardContains(trimmedQuery)
                    || item.subsystemLabel.localizedStandardContains(trimmedQuery)
            }
        }
        if isShowingPinnedOnly {
            return switches.filter { pinnedSwitchIDs.contains($0.id) }
        }
        return switches.filter { item in
            selectedDomainFilter == nil || item.domain == selectedDomainFilter
        }
    }

    public var activeSwitchCount: Int {
        switches.filter { $0.state.isEnabled }.count
    }

    public var pinnedCounts: (active: Int, total: Int) {
        var active = 0
        var total = 0
        for item in switches where pinnedSwitchIDs.contains(item.id) {
            total += 1
            if item.state.isEnabled {
                active += 1
            }
        }
        return (active, total)
    }

    public func isPinned(_ switchID: String) -> Bool {
        pinnedSwitchIDs.contains(switchID)
    }

    public func togglePin(forSwitchID switchID: String) {
        if pinnedSwitchIDs.contains(switchID) {
            pinnedSwitchIDs.remove(switchID)
        } else {
            pinnedSwitchIDs.insert(switchID)
        }
        userDefaults.set(Array(pinnedSwitchIDs).sorted(), forKey: Self.pinnedSwitchesStorageKey)
    }

    public func restoreDefaultPins() {
        pinnedSwitchIDs = Set(Self.defaultPinnedSwitchIDs)
        userDefaults.set(Self.defaultPinnedSwitchIDs, forKey: Self.pinnedSwitchesStorageKey)
    }

    public func selectPinnedFilter() {
        isShowingPinnedOnly = true
    }

    public func selectDomainFilter(_ domain: SwitchDomain?) {
        selectedDomainFilter = domain
        isShowingPinnedOnly = false
    }

    public func domainCounts(for domain: SwitchDomain) -> (active: Int, total: Int) {
        var active = 0
        var total = 0
        for item in switches where item.domain == domain {
            total += 1
            if item.state.isEnabled {
                active += 1
            }
        }
        return (active, total)
    }

    public func triggerSwitch(withID id: String) async {
        guard let target = switches.first(where: { $0.id == id }) else { return }
        await target.trigger()
        totalTriggerCount += 1
        userDefaults.set(totalTriggerCount, forKey: triggerCountStorageKey)
        refreshDiskVolumes()
        refreshHardwareTelemetry()
    }

    public func refreshDiskVolumes() {
        let updated = DiskVolumeTelemetryService.listMountedVolumes()
        if mountedVolumes != updated {
            mountedVolumes = updated
        }
        if !updated.contains(where: { $0.id == selectedVolumeID }), let first = updated.first {
            selectedVolumeID = first.id
        }
    }

    public var selectedVolumeIndex: Int {
        guard let idx = mountedVolumes.firstIndex(where: { $0.id == selectedVolumeID }) else {
            return mountedVolumes.isEmpty ? 0 : 1
        }
        return idx + 1
    }

    public func cycleNextVolume() {
        guard !mountedVolumes.isEmpty else { return }
        if let idx = mountedVolumes.firstIndex(where: { $0.id == selectedVolumeID }) {
            let nextIdx = (idx + 1) % mountedVolumes.count
            selectedVolumeID = mountedVolumes[nextIdx].id
        } else if let first = mountedVolumes.first {
            selectedVolumeID = first.id
        }
    }

    public func cyclePreviousVolume() {
        guard !mountedVolumes.isEmpty else { return }
        if let idx = mountedVolumes.firstIndex(where: { $0.id == selectedVolumeID }) {
            let prevIdx = (idx - 1 + mountedVolumes.count) % mountedVolumes.count
            selectedVolumeID = mountedVolumes[prevIdx].id
        } else if let first = mountedVolumes.first {
            selectedVolumeID = first.id
        }
    }

    public func ejectSelectedVolume() {
        guard let current = selectedVolume, current.isEjectable else { return }
        if DiskVolumeTelemetryService.ejectVolume(current) {
            totalTriggerCount += 1
            userDefaults.set(totalTriggerCount, forKey: triggerCountStorageKey)
        }
        refreshDiskVolumes()
    }

    public func revealSelectedVolumeInFinder() {
        guard let current = selectedVolume else { return }
        DiskVolumeTelemetryService.revealInFinder(current)
    }

    public var selectedBluetoothDevice: BluetoothDeviceItem? {
        if let match = pairedBluetoothDevices.first(where: { $0.id == selectedBluetoothDeviceID }) {
            return match
        }
        return pairedBluetoothDevices.first
    }

    public var selectedBluetoothIndex: Int {
        guard let idx = pairedBluetoothDevices.firstIndex(where: { $0.id == selectedBluetoothDeviceID }) else {
            return pairedBluetoothDevices.isEmpty ? 0 : 1
        }
        return idx + 1
    }

    public var connectedBluetoothCount: Int {
        pairedBluetoothDevices.filter(\.isConnected).count
    }

    public func refreshBluetoothDevices() {
        let updated = BluetoothDeviceService.listPairedDevices()
        if pairedBluetoothDevices != updated {
            pairedBluetoothDevices = updated
        }
        if !updated.contains(where: { $0.id == selectedBluetoothDeviceID }), let first = updated.first {
            selectedBluetoothDeviceID = first.id
        }
    }

    public func cycleNextBluetoothDevice() {
        guard !pairedBluetoothDevices.isEmpty else { return }
        if let idx = pairedBluetoothDevices.firstIndex(where: { $0.id == selectedBluetoothDeviceID }) {
            let nextIdx = (idx + 1) % pairedBluetoothDevices.count
            selectedBluetoothDeviceID = pairedBluetoothDevices[nextIdx].id
        } else if let first = pairedBluetoothDevices.first {
            selectedBluetoothDeviceID = first.id
        }
        Task {
            if let btSwitch = switches.first(where: { $0.id == "SW.17" }) {
                await btSwitch.refreshState()
            }
        }
    }

    public func cyclePreviousBluetoothDevice() {
        guard !pairedBluetoothDevices.isEmpty else { return }
        if let idx = pairedBluetoothDevices.firstIndex(where: { $0.id == selectedBluetoothDeviceID }) {
            let prevIdx = (idx - 1 + pairedBluetoothDevices.count) % pairedBluetoothDevices.count
            selectedBluetoothDeviceID = pairedBluetoothDevices[prevIdx].id
        } else if let first = pairedBluetoothDevices.first {
            selectedBluetoothDeviceID = first.id
        }
        Task {
            if let btSwitch = switches.first(where: { $0.id == "SW.17" }) {
                await btSwitch.refreshState()
            }
        }
    }

    public func toggleSelectedBluetoothDevice() async {
        guard let current = selectedBluetoothDevice else { return }
        await toggleBluetoothDevice(current)
    }

    public func toggleBluetoothDevice(_ device: BluetoothDeviceItem) async {
        selectedBluetoothDeviceID = device.id
        connectingBluetoothDeviceID = device.id
        let shouldConnect = !device.isConnected
        _ = await BluetoothDeviceService.setConnection(address: device.address, connect: shouldConnect)
        connectingBluetoothDeviceID = nil
        totalTriggerCount += 1
        userDefaults.set(totalTriggerCount, forKey: triggerCountStorageKey)
        refreshBluetoothDevices()
        if let btSwitch = switches.first(where: { $0.id == "SW.17" }) {
            await btSwitch.refreshState()
        }
    }

    public func refreshHardwareTelemetry() {
        let updated = HardwareTelemetryService.shared.captureSnapshot()
        if hardwareTelemetry != updated {
            hardwareTelemetry = updated
        }
    }

    private func refreshSwitch(withID id: String) async {
        guard let item = switches.first(where: { $0.id == id }) else { return }
        await item.refreshState()
    }

    public func refreshAll() async {
        refreshHardwareTelemetry()
        refreshDiskVolumes()
        refreshBluetoothDevices()

        let pinnedOnly = isShowingPinnedOnly
        let currentPins = pinnedSwitchIDs
        let activeDomain = selectedDomainFilter
        let primaryIDs = switches
            .filter { item in
                if pinnedOnly {
                    return currentPins.contains(item.id)
                }
                return activeDomain == nil || item.domain == activeDomain
            }
            .map(\.id)
        let primarySet = Set(primaryIDs)
        let secondaryIDs = switches
            .map(\.id)
            .filter { !primarySet.contains($0) }

        await withTaskGroup(of: Void.self) { group in
            for id in primaryIDs {
                group.addTask { @MainActor [weak self] in
                    await self?.refreshSwitch(withID: id)
                }
            }
        }

        await withTaskGroup(of: Void.self) { group in
            for id in secondaryIDs {
                group.addTask { @MainActor [weak self] in
                    await self?.refreshSwitch(withID: id)
                }
            }
        }
    }
}
