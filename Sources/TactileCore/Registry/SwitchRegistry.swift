import Foundation
import Observation

@Observable
@MainActor
public final class SwitchRegistry {
    public private(set) var switches: [any TactileSwitchProtocol]
    public var selectedDomainFilter: SwitchDomain? = .power
    public var searchQuery: String = ""
    public var isShowingSupportSheet: Bool = false
    public var isShowingRadialDial: Bool = true
    public var availableUpdate: ReleaseUpdateInfo?
    public private(set) var mountedVolumes: [MountedVolumeInfo] = []
    public var selectedVolumeID: String = "/"
    public private(set) var totalTriggerCount: Int

    private let triggerCountStorageKey = "studio.tactile.TactileBar.totalTriggerCount"
    private let userDefaults: UserDefaults

    public init(
        switches: [any TactileSwitchProtocol],
        userDefaults: UserDefaults = .standard
    ) {
        self.switches = switches
        self.userDefaults = userDefaults
        self.totalTriggerCount = userDefaults.integer(forKey: triggerCountStorageKey)
        let initialVolumes = DiskVolumeTelemetryService.listMountedVolumes()
        self.mountedVolumes = initialVolumes
        if let first = initialVolumes.first {
            self.selectedVolumeID = first.id
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
                item.title.localizedCaseInsensitiveContains(trimmedQuery)
                    || item.id.localizedCaseInsensitiveContains(trimmedQuery)
                    || item.subsystemLabel.localizedCaseInsensitiveContains(trimmedQuery)
            }
        }
        return switches.filter { item in
            selectedDomainFilter == nil || item.domain == selectedDomainFilter
        }
    }

    public var activeSwitchCount: Int {
        switches.filter { $0.state.isEnabled }.count
    }

    public func triggerSwitch(withID id: String) async {
        guard let target = switches.first(where: { $0.id == id }) else { return }
        await target.trigger()
        totalTriggerCount += 1
        userDefaults.set(totalTriggerCount, forKey: triggerCountStorageKey)
        refreshDiskVolumes()
    }

    public func refreshDiskVolumes() {
        let updated = DiskVolumeTelemetryService.listMountedVolumes()
        mountedVolumes = updated
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

    public var isShowingVolumeList: Bool = false

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

    public func refreshAll() async {
        refreshDiskVolumes()
        for item in switches {
            await item.refreshState()
        }
    }
}
