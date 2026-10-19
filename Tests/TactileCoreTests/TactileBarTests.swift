import Foundation
import SwitchCatalog
import TactileCore
import XCTest

@MainActor
final class TactileBarTests: XCTestCase {
    func testCatalogContainsAllTwentySixUniqueSwitches() {
        let switches = TactileSwitchCatalog.makeAllSwitches()
        XCTAssertEqual(switches.count, AppConfiguration.totalCatalogSwitchCount)

        let ids = switches.map(\.id)
        let uniqueIDs = Set(ids)
        XCTAssertEqual(uniqueIDs.count, 26)
        XCTAssertEqual(ids.first, "SW.01")
        XCTAssertEqual(ids.last, "SW.26")
    }

    func testDomainDistributionMatchesTelemetryCatalog() {
        let switches = TactileSwitchCatalog.makeAllSwitches()
        let powerCount = switches.filter { $0.domain == .power }.count
        let opticsCount = switches.filter { $0.domain == .optics }.count
        let workspaceCount = switches.filter { $0.domain == .workspace }.count
        let signalCount = switches.filter { $0.domain == .signal }.count
        let securityCount = switches.filter { $0.domain == .security }.count

        XCTAssertEqual(powerCount, 5)
        XCTAssertEqual(opticsCount, 4)
        XCTAssertEqual(workspaceCount, 6)
        XCTAssertEqual(signalCount, 3)
        XCTAssertEqual(securityCount, 8)
    }

    func testRegistryDomainAndSearchFiltering() {
        let suiteName = "studio.tactile.TactileBarTests.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }

        let switches = TactileSwitchCatalog.makeAllSwitches()
        let registry = SwitchRegistry(switches: switches, userDefaults: testDefaults)

        // Starts on the curated Pinned Deck ("Less, but better" — 6 default pins)
        XCTAssertTrue(registry.isShowingPinnedOnly)
        XCTAssertEqual(registry.filteredSwitches.count, 6)

        // Selecting a domain exits Pinned mode and filters by domain
        registry.selectDomainFilter(.power)
        XCTAssertFalse(registry.isShowingPinnedOnly)
        XCTAssertEqual(registry.filteredSwitches.count, 5)

        registry.selectedDomainFilter = nil
        XCTAssertEqual(registry.filteredSwitches.count, 26)

        registry.selectedDomainFilter = .signal
        XCTAssertEqual(registry.filteredSwitches.count, 3)

        registry.searchQuery = "XCODE"
        XCTAssertEqual(registry.filteredSwitches.count, 1)
        XCTAssertEqual(registry.filteredSwitches.first?.id, "SW.25")
    }

    func testRegistryPinToggleAndRestore() {
        let suiteName = "studio.tactile.TactileBarTests.Pins.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }

        let switches = TactileSwitchCatalog.makeAllSwitches()
        let registry = SwitchRegistry(switches: switches, userDefaults: testDefaults)

        XCTAssertTrue(registry.isPinned("SW.01"))
        registry.togglePin(forSwitchID: "SW.01")
        XCTAssertFalse(registry.isPinned("SW.01"))
        XCTAssertEqual(registry.pinnedCounts.total, 5)

        registry.restoreDefaultPins()
        XCTAssertTrue(registry.isPinned("SW.01"))
        XCTAssertEqual(registry.pinnedCounts.total, 6)
    }

    func testSemanticVersionComparison() {
        XCTAssertTrue(GitHubReleaseChecker.isVersion("1.1.0", newerThan: "1.0.0"))
        XCTAssertTrue(GitHubReleaseChecker.isVersion("2.0.0", newerThan: "1.9.9"))
        XCTAssertFalse(GitHubReleaseChecker.isVersion("1.0.0", newerThan: "1.0.0"))
        XCTAssertFalse(GitHubReleaseChecker.isVersion("0.9.5", newerThan: "1.0.0"))
        XCTAssertEqual(GitHubReleaseChecker.normalizeSemanticVersion("v1.4.2"), "1.4.2")
    }

    func testNativeQRCodeGeneratorProducesValidImage() {
        let image = QRCodeGeneratorService.generateCGImage(from: AppConfiguration.sponsorURL, dimension: 120)
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.width, 120)
        XCTAssertEqual(image?.height, 120)
    }

    func testHardwareTelemetrySnapshotProducesValidMetrics() {
        let snapshot = HardwareTelemetryService.shared.captureSnapshot()
        XCTAssertGreaterThan(snapshot.cpuTotalRatio, 0.0)
        XCTAssertLessThanOrEqual(snapshot.cpuTotalRatio, 1.0)
        XCTAssertGreaterThan(snapshot.memoryUsedRatio, 0.0)
        XCTAssertLessThanOrEqual(snapshot.memoryUsedRatio, 1.0)
        XCTAssertFalse(snapshot.memoryFormattedRatio.isEmpty)
        XCTAssertFalse(snapshot.thermalStateLabel.isEmpty)
    }

    func testRegistryDomainCounts() {
        let switches = TactileSwitchCatalog.makeAllSwitches()
        let registry = SwitchRegistry(switches: switches)

        XCTAssertEqual(registry.domainCounts(for: .power).total, 5)
        XCTAssertEqual(registry.domainCounts(for: .optics).total, 4)
        XCTAssertEqual(registry.domainCounts(for: .workspace).total, 6)
        XCTAssertEqual(registry.domainCounts(for: .signal).total, 3)
        XCTAssertEqual(registry.domainCounts(for: .security).total, 8)
    }
}
