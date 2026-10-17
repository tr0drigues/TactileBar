import Foundation
import Observation

@Observable
@MainActor
public final class SwitchRegistry {
    public private(set) var switches: [any TactileSwitchProtocol]
    public var selectedDomainFilter: SwitchDomain?
    public var searchQuery: String = ""
    public var isShowingSupportSheet: Bool = false
    public var availableUpdate: ReleaseUpdateInfo?
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
    }

    public var filteredSwitches: [any TactileSwitchProtocol] {
        switches.filter { item in
            let matchesDomain = selectedDomainFilter == nil || item.domain == selectedDomainFilter
            let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = trimmedQuery.isEmpty
                || item.title.localizedCaseInsensitiveContains(trimmedQuery)
                || item.id.localizedCaseInsensitiveContains(trimmedQuery)
                || item.subsystemLabel.localizedCaseInsensitiveContains(trimmedQuery)
            return matchesDomain && matchesSearch
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
    }

    public func refreshAll() async {
        for item in switches {
            await item.refreshState()
        }
    }
}
