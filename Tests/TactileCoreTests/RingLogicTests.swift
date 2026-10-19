import Foundation
import SwitchCatalog
import TactileCore
import XCTest

final class RingGeometryTests: XCTestCase {
    func testCardinalsComeFirstThenDiagonals() {
        XCTAssertEqual(RingGeometry.slot(dx: 0, dy: -100, deadZoneRadius: 59), 0)
        XCTAssertEqual(RingGeometry.slot(dx: 100, dy: 0, deadZoneRadius: 59), 1)
        XCTAssertEqual(RingGeometry.slot(dx: 0, dy: 100, deadZoneRadius: 59), 2)
        XCTAssertEqual(RingGeometry.slot(dx: -100, dy: 0, deadZoneRadius: 59), 3)
        XCTAssertEqual(RingGeometry.slot(dx: 70, dy: -70, deadZoneRadius: 59), 4)
        XCTAssertEqual(RingGeometry.slot(dx: 70, dy: 70, deadZoneRadius: 59), 5)
        XCTAssertEqual(RingGeometry.slot(dx: -70, dy: 70, deadZoneRadius: 59), 6)
        XCTAssertEqual(RingGeometry.slot(dx: -70, dy: -70, deadZoneRadius: 59), 7)
    }

    func testDeadZoneAndNullVector() {
        XCTAssertNil(RingGeometry.slot(dx: 30, dy: 20, deadZoneRadius: 59))
        XCTAssertNil(RingGeometry.slot(dx: 0, dy: 0, deadZoneRadius: 59))
    }

    func testSlotBoundaries() {
        // 20° ao lado do sul continua no sul; 25° já passa para a diagonal.
        let angle20 = (90.0 - 20.0) * Double.pi / 180.0
        XCTAssertEqual(RingGeometry.slot(dx: cos(angle20) * 100, dy: sin(angle20) * 100, deadZoneRadius: 59), 2)
        let angle25 = (90.0 - 25.0) * Double.pi / 180.0
        XCTAssertEqual(RingGeometry.slot(dx: cos(angle25) * 100, dy: sin(angle25) * 100, deadZoneRadius: 59), 5)
    }
}

final class RingOrderingTests: XCTestCase {
    func testRankedByUsageWithPinOrderTieBreak() {
        let ranked = RingOrdering.rankedByUsage(
            pinnedOrder: ["SW.01", "SW.06", "SW.10", "SW.16"],
            usageCounts: ["SW.16": 9, "SW.06": 3, "SW.10": 3]
        )
        XCTAssertEqual(ranked, ["SW.16", "SW.06", "SW.10", "SW.01"])
    }

    func testWithoutHistoryKeepsPinOrder() {
        let ranked = RingOrdering.rankedByUsage(pinnedOrder: ["SW.25", "SW.01"], usageCounts: [:])
        XCTAssertEqual(RingOrdering.layout(ranked: ranked), ["SW.25", "SW.01", nil, nil, nil, nil, nil, nil])
    }

    func testRemovingAPinDoesNotMoveOthers() {
        let slots: [String?] = ["SW.16", "SW.06", "SW.10", nil, nil, nil, nil, nil]
        let result = RingOrdering.reconcile(slots: slots, pinnedOrder: ["SW.16", "SW.10"], usageCounts: [:])
        XCTAssertEqual(result, ["SW.16", nil, "SW.10", nil, nil, nil, nil, nil])
    }

    func testNewPinTakesFirstFreeSlot() {
        let slots: [String?] = ["SW.16", nil, "SW.10", nil, nil, nil, nil, nil]
        let result = RingOrdering.reconcile(slots: slots, pinnedOrder: ["SW.16", "SW.10", "SW.22"], usageCounts: [:])
        XCTAssertEqual(result[1], "SW.22")
        XCTAssertEqual(result[0], "SW.16")
        XCTAssertEqual(result[2], "SW.10")
    }

    func testUsageChangesDoNotReorderWithoutTrigger() {
        let slots: [String?] = ["SW.01", "SW.06", nil, nil, nil, nil, nil, nil]
        let result = RingOrdering.reconcile(slots: slots, pinnedOrder: ["SW.01", "SW.06"], usageCounts: ["SW.06": 50])
        XCTAssertEqual(result, slots)
    }

    func testOverflowAboveEightPins() {
        let pins = (1...10).map { String(format: "SW.%02d", $0) }
        let layout = RingOrdering.layout(ranked: pins)
        XCTAssertEqual(RingOrdering.overflowCount(slots: layout, pinnedOrder: pins), 2)
    }
}

final class RingSessionTests: XCTestCase {
    private let entries: [RingSlotEntry?] = [
        RingSlotEntry(switchID: "SW.16", isDestructive: false, isActionable: true),
        RingSlotEntry(switchID: "SW.25", isDestructive: true, isActionable: true),
        RingSlotEntry(switchID: "SW.09", isDestructive: false, isActionable: false),
        nil, nil, nil, nil, nil
    ]

    func testHoldMoveReleaseFires() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: 0, dy: -100, at: 0.1)
        XCTAssertEqual(session.hotKeyReleased(at: 0.4), .fire(switchID: "SW.16"))
        XCTAssertFalse(session.isOpen)
    }

    func testReleaseTooFastCancels() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: 0, dy: -100, at: 0.02)
        XCTAssertEqual(session.hotKeyReleased(at: 0.08), .dismiss)
    }

    func testQuickTapLatchesAndEscapeCloses() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        XCTAssertEqual(session.hotKeyReleased(at: 0.1), RingOutcome.none)
        XCTAssertEqual(session.phase, .latched)
        XCTAssertEqual(session.cancel(), .dismiss)
        XCTAssertFalse(session.isOpen)
    }

    func testLatchedDigitAndConfirm() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        _ = session.hotKeyReleased(at: 0.1)
        session.select(slot: 0, at: 1)
        XCTAssertEqual(session.confirm(at: 1), .fire(switchID: "SW.16"))
    }

    func testReturningToCenterCancels() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: 0, dy: -100, at: 0.1)
        session.pointerMoved(dx: 5, dy: 5, at: 0.2)
        XCTAssertTrue(session.wouldCancelOnRelease)
        XCTAssertEqual(session.hotKeyReleased(at: 0.4), .dismiss)
    }

    func testDestructiveRequiresArming() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: 100, dy: 0, at: 0.3)
        XCTAssertLessThan(session.armingProgress(at: 0.45), 1)
        XCTAssertEqual(session.hotKeyReleased(at: 0.4), .dismiss)

        session.open(slots: entries, at: 10)
        session.pointerMoved(dx: 100, dy: 0, at: 10.3)
        XCTAssertEqual(session.hotKeyReleased(at: 10.7), .fire(switchID: "SW.25"))
    }

    func testUnavailableSwitchNeverFires() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: 0, dy: 100, at: 0.3)
        XCTAssertEqual(session.focusedSlot, 2)
        XCTAssertEqual(session.hotKeyReleased(at: 0.5), .dismiss)
    }

    func testEmptySlotGetsNoFocus() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: -100, dy: 0, at: 0.3)
        XCTAssertNil(session.focusedSlot)
    }

    func testRotateFocusFollowsClockwiseVisualOrder() {
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        session.rotateFocus(clockwise: true, at: 0.1)
        XCTAssertEqual(session.focusedSlot, 0)
        session.rotateFocus(clockwise: true, at: 0.2)
        XCTAssertEqual(session.focusedSlot, 1)
        session.rotateFocus(clockwise: true, at: 0.3)
        XCTAssertEqual(session.focusedSlot, 2)
        session.rotateFocus(clockwise: true, at: 0.4)
        XCTAssertEqual(session.focusedSlot, 0)
    }
}

@MainActor
final class RingRegistryTests: XCTestCase {
    func testPinOrderUsageCountsAndRingSlotsPersist() {
        let suiteName = "studio.tactile.TactileBarTests.Ring.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }
        testDefaults.set(["SW.16", "SW.01"], forKey: SwitchRegistry.pinnedSwitchesStorageKey)

        let registry = SwitchRegistry(switches: TactileSwitchCatalog.makeAllSwitches(), userDefaults: testDefaults)
        XCTAssertEqual(registry.pinnedOrder, ["SW.16", "SW.01"])
        XCTAssertEqual(registry.ringSlots[0], "SW.16")

        registry.togglePin(forSwitchID: "SW.06")
        XCTAssertEqual(registry.ringSlots[2], "SW.06")

        let reloaded = SwitchRegistry(switches: TactileSwitchCatalog.makeAllSwitches(), userDefaults: testDefaults)
        XCTAssertEqual(reloaded.pinnedOrder, ["SW.16", "SW.01", "SW.06"])
        XCTAssertEqual(reloaded.ringSlots, registry.ringSlots)
    }

    func testReorderByUsageIsExplicit() {
        let suiteName = "studio.tactile.TactileBarTests.RingReorder.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName)!
        defer { testDefaults.removePersistentDomain(forName: suiteName) }
        testDefaults.set(["SW.01", "SW.06"], forKey: SwitchRegistry.pinnedSwitchesStorageKey)
        testDefaults.set(["SW.06": 12], forKey: SwitchRegistry.switchTriggerCountsStorageKey)
        testDefaults.set(["SW.01", "SW.06", "", "", "", "", "", ""], forKey: SwitchRegistry.ringSlotsStorageKey)

        let registry = SwitchRegistry(switches: TactileSwitchCatalog.makeAllSwitches(), userDefaults: testDefaults)
        XCTAssertEqual(registry.ringSlots[0], "SW.01")

        registry.reorderRingByUsage()
        XCTAssertEqual(registry.ringSlots[0], "SW.06")
        XCTAssertEqual(registry.ringSlots[1], "SW.01")
    }
}

@MainActor
final class RingChoiceTests: XCTestCase {
    private let entries: [RingSlotEntry?] = [
        RingSlotEntry(switchID: "SW.16", isDestructive: false, isActionable: true),
        nil, nil,
        RingSlotEntry(switchID: "SW.17", isDestructive: false, isActionable: true, choiceIDs: ["A", "B", "C"]),
        nil, nil, nil, nil
    ]

    private func point(angle: Double, radius: Double) -> (Double, Double) {
        (radius * cos(angle * Double.pi / 180), radius * sin(angle * Double.pi / 180))
    }

    func testFanIsCenteredOnSlice() {
        XCTAssertEqual(RingGeometry.choiceAngles(count: 3, aroundSlot: 3), [159, 180, 201])
        XCTAssertNil(RingGeometry.choice(dx: 160, dy: 0, count: 3, aroundSlot: 3))
    }

    func testChoicesAreCappedAtEight() {
        let entry = RingSlotEntry(switchID: "SW.17", isDestructive: false, isActionable: true, choiceIDs: (0..<11).map(String.init))
        XCTAssertEqual(entry.choiceIDs.count, 8)
    }

    func testReleaseOnSliceUsesPreferred() {
        var session = RingSession(deadZoneRadius: 59, expandRadius: 133)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: -100, dy: 0, at: 0.1)
        XCTAssertNil(session.expandedSlot)
        XCTAssertEqual(session.hotKeyReleased(at: 0.3), .fire(switchID: "SW.17"))
    }

    func testPushPastEdgeOpensFanAndReleaseFiresChoice() {
        var session = RingSession(deadZoneRadius: 59, expandRadius: 133)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: -100, dy: 0, at: 0.1)
        session.pointerMoved(dx: -160, dy: 0, at: 0.2)
        XCTAssertEqual(session.expandedSlot, 3)
        XCTAssertEqual(session.focusedChoice, 1)
        let (dx, dy) = point(angle: 201, radius: 160)
        session.pointerMoved(dx: dx, dy: dy, at: 0.3)
        XCTAssertEqual(session.hotKeyReleased(at: 0.4), .fireChoice(switchID: "SW.17", choiceID: "C"))
    }

    func testBackToCenterCollapses() {
        var session = RingSession(deadZoneRadius: 59, expandRadius: 133)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: -160, dy: 0, at: 0.2)
        session.pointerMoved(dx: 0, dy: 10, at: 0.3)
        XCTAssertNil(session.expandedSlot)
        XCTAssertNil(session.focusedSlot)
    }

    func testDwellOpensFan() {
        var session = RingSession(deadZoneRadius: 59, expandRadius: 133)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: -100, dy: 0, at: 0.1)
        session.advance(to: 0.3)
        XCTAssertNil(session.expandedSlot)
        session.advance(to: 0.6)
        XCTAssertEqual(session.expandedSlot, 3)
        XCTAssertNil(session.focusedChoice)
        XCTAssertEqual(session.hotKeyReleased(at: 0.7), .fire(switchID: "SW.17"))
    }

    func testKeyboardInLatchedMode() {
        var session = RingSession(deadZoneRadius: 59, expandRadius: 133)
        session.open(slots: entries, at: 0)
        _ = session.hotKeyReleased(at: 0.1)
        session.select(slot: 3, at: 0.2)
        session.toggleExpansion()
        session.rotateFocus(clockwise: true, at: 0.3)
        XCTAssertEqual(session.focusedChoice, 1)
        session.collapse()
        session.advance(to: 5)
        XCTAssertNil(session.expandedSlot)
        XCTAssertEqual(session.focusedSlot, 3)
        session.toggleExpansion()
        session.select(choice: 2)
        XCTAssertEqual(session.confirm(at: 5.1), .fireChoice(switchID: "SW.17", choiceID: "C"))
    }

    func testSliceWithoutChoicesNeverExpands() {
        var session = RingSession(deadZoneRadius: 59, expandRadius: 133)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: 0, dy: -170, at: 0.1)
        session.advance(to: 2)
        XCTAssertNil(session.expandedSlot)
        XCTAssertEqual(session.hotKeyReleased(at: 2.1), .fire(switchID: "SW.16"))
    }
}
