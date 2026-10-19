import AppKit
import Carbon.HIToolbox
import os
import SwiftUI
import TactileCore

private let ringLog = Logger(subsystem: "studio.tactile.TactileBar", category: "ring")

/// Liga o atalho global, a sessão do anel, o painel e o `SwitchRegistry`.
@MainActor
public final class RingController {
    private let registry: SwitchRegistry
    private let model = RingViewModel()
    private var session: RingSession
    private lazy var panel: RingPanel = {
        let hostingView = RingHostingView(rootView: RingView(model: model))
        hostingView.onPrimaryClick = { [weak self] in self?.panelClicked() }
        hostingView.onSecondaryClick = { [weak self] in
            guard let self else { return }
            ringLog.notice("secondary click: cancel")
            self.handle(self.session.cancel())
        }
        return RingPanel(contentView: hostingView)
    }()

    /// Modo fixo sem interação por este tempo fecha sozinho, para nunca prender as teclas capturadas.
    private static let latchedIdleTimeout: TimeInterval = 8
    private var lastInteractionAt: TimeInterval = 0
    private var lastPointerLocation: NSPoint?

    private var triggerHotKeyID: UInt32?
    private var transientHotKeyIDs: [UInt32] = []
    private var trackingTimer: Timer?
    private var mouseMonitors: [Any] = []
    private var ringCenter: NSPoint = .zero
    private var announcedFocus: Int?
    private var announcedChoice: Int?
    private var executionFinished = true

    private static let triggerKeyCode = kVK_Space
    private static let triggerModifiers = controlKey | optionKey
    private static let digitKeyCodes = [
        kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4,
        kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8
    ]

    public init(registry: SwitchRegistry) {
        self.registry = registry
        self.session = RingSession(
            timing: registry.ringPreferences.timing,
            deadZoneRadius: Double(RingMetrics.deadZoneRadius),
            expandRadius: Double(RingMetrics.choiceExpandRadius)
        )
    }

    /// Começa a observar a preferência; registra o atalho só se o anel estiver ativado.
    public func start() {
        registry.ringPreferences.onChange = { [weak self] in
            self?.applyPreferences()
        }
        applyPreferences()
    }

    private func applyPreferences() {
        if registry.ringPreferences.isEnabled {
            guard triggerHotKeyID == nil else { return }
            triggerHotKeyID = RingHotKeyCenter.shared.register(
                keyCode: Self.triggerKeyCode,
                modifiers: Self.triggerModifiers,
                onPress: { [weak self] in self?.triggerPressed() },
                onRelease: { [weak self] in self?.triggerReleased() }
            )
        } else {
            if let triggerHotKeyID {
                RingHotKeyCenter.shared.unregister(triggerHotKeyID)
            }
            triggerHotKeyID = nil
            if session.isOpen {
                handle(session.cancel())
            }
        }
    }

    // MARK: - Trigger

    private func triggerPressed() {
        guard model.executingRank == nil else { return }
        if session.isOpen {
            ringLog.notice("trigger pressed while open: cancel")
            handle(session.cancel())
        } else {
            open()
        }
    }

    private func triggerReleased() {
        guard session.phase == .holding else { return }
        let outcome = session.hotKeyReleased(at: now)
        ringLog.notice("trigger released: \(String(describing: outcome), privacy: .public), phase \(String(describing: self.session.phase), privacy: .public)")
        handle(outcome)
        if session.phase == .latched {
            enterLatchedMode()
        }
    }

    private func panelClicked() {
        guard session.isOpen else { return }
        if session.phase == .holding {
            // Clique enquanto segura o atalho: trata como soltar sobre a fatia apontada.
            tick()
            triggerReleased()
            return
        }
        tick()
        let outcome = session.confirm(at: now)
        ringLog.notice("panel click: \(String(describing: outcome), privacy: .public)")
        handle(outcome)
    }

    private func open() {
        registry.refreshBluetoothDevices()
        var choicesByRank: [Int: [RingChoice]] = [:]
        var overflowByRank: [Int: Int] = [:]
        let entries: [RingSlotEntry?] = registry.ringSlots.enumerated().map { rank, id in
            guard let id, let item = registry.switchItem(withID: id) else { return nil }
            let allChoices = registry.ringChoices(forSwitchID: id)
            let shown = Array(allChoices.prefix(RingGeometry.maxChoices))
            if !shown.isEmpty {
                choicesByRank[rank] = shown
                overflowByRank[rank] = allChoices.count - shown.count
            }
            return RingSlotEntry(
                switchID: id,
                isDestructive: RingPreferences.isDestructive(id),
                isActionable: Self.isActionable(item.state),
                choiceIDs: shown.map(\.id)
            )
        }
        guard entries.contains(where: { $0 != nil }) else {
            NSSound.beep()
            return
        }

        session.open(slots: entries, at: now)
        model.slots = registry.ringSlots.enumerated().compactMap { rank, id in
            guard let id, let item = registry.switchItem(withID: id) else { return nil }
            return RingViewModel.Slot(rank: rank, item: item, isDestructive: RingPreferences.isDestructive(id))
        }
        model.emptyRanks = registry.ringSlots.indices.filter { registry.ringSlots[$0] == nil }
        model.overflowCount = registry.ringOverflowCount
        model.choices = choicesByRank
        model.choiceOverflow = overflowByRank
        model.expandedRank = nil
        model.focusedChoice = nil
        model.executingChoice = nil
        model.isLatched = false
        model.executingRank = nil
        announcedFocus = nil
        announcedChoice = nil
        lastPointerLocation = nil
        syncModel()

        panel.ignoresMouseEvents = true
        ringCenter = panel.present(at: NSEvent.mouseLocation)
        lastInteractionAt = now
        startTracking()
        registerTransientKeys(latched: false)
        ringLog.notice("open: \(self.model.slots.count) slots")
        announce("Ring open, \(model.slots.count) items")

        // Mostra o último estado conhecido na hora e atualiza em seguida.
        let items = model.slots.map(\.item)
        Task {
            for item in items {
                await item.refreshState()
            }
        }
    }

    private func enterLatchedMode() {
        model.isLatched = true
        lastInteractionAt = now
        panel.ignoresMouseEvents = false
        registerTransientKeys(latched: true)
        // Cliques dentro do painel chegam pelo RingHostingView; aqui só os cliques em outros apps.
        let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                ringLog.notice("click outside: cancel")
                self.handle(self.session.cancel())
            }
        }
        mouseMonitors = [global].compactMap { $0 }
        ringLog.notice("latched")
    }

    // MARK: - Outcomes

    private func handle(_ outcome: RingOutcome) {
        switch outcome {
        case .none:
            syncModel()
        case .dismiss:
            close()
        case .fire(let switchID):
            execute(switchID, choiceID: nil)
        case .fireChoice(let switchID, let choiceID):
            execute(switchID, choiceID: choiceID)
        }
    }

    private func execute(_ switchID: String, choiceID: String?) {
        stopInput()
        let rank = registry.ringSlots.firstIndex(of: switchID)
        let choiceIndex = rank.flatMap { model.choices[$0] }?.firstIndex(where: { $0.id == choiceID })
        model.focusedRank = nil
        model.executingRank = rank
        model.executingChoice = choiceIndex
        model.expandedRank = choiceIndex == nil ? nil : rank
        let choiceTitle = choiceIndex.flatMap { index in rank.flatMap { model.choices[$0]?[index].title } }
        announce("\(choiceTitle ?? registry.switchItem(withID: switchID)?.title ?? switchID) triggered")
        ringLog.notice("fire \(switchID, privacy: .public) choice \(choiceID ?? "-", privacy: .public)")

        executionFinished = false
        Task { [weak self] in
            guard let self else { return }
            if let choiceID {
                await self.registry.triggerRingChoice(switchID: switchID, choiceID: choiceID)
            } else {
                await self.registry.triggerSwitch(withID: switchID)
            }
            self.executionFinished = true
        }
        Task { [weak self] in
            // Mostra a execução por um instante; o switch continua rodando se demorar mais.
            let deadline = ContinuousClock.now + .milliseconds(1200)
            try? await Task.sleep(for: .milliseconds(220))
            while let self, !self.executionFinished, ContinuousClock.now < deadline {
                try? await Task.sleep(for: .milliseconds(50))
            }
            self?.close()
        }
    }

    private func close() {
        ringLog.notice("close")
        stopInput()
        panel.dismiss()
        model.executingRank = nil
        model.focusedRank = nil
        model.expandedRank = nil
        model.focusedChoice = nil
        model.executingChoice = nil
        model.isLatched = false
        model.wouldCancel = false
    }

    // MARK: - Input while open

    private func startTracking() {
        trackingTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        trackingTimer = timer
    }

    private func tick() {
        guard session.isOpen else { return }

        // Não depende só do evento de "soltar" do Carbon: soltar ⌃ ou ⌥ também conta como soltar.
        if session.phase == .holding && !NSEvent.modifierFlags.contains([.control, .option]) {
            ringLog.notice("modifiers released while holding")
            triggerReleased()
            if !session.isOpen { return }
        }

        if session.phase == .latched && now - lastInteractionAt > Self.latchedIdleTimeout {
            ringLog.notice("latched idle timeout: cancel")
            handle(session.cancel())
            return
        }

        let previousFocus = session.focusedSlot
        let previousExpansion = session.expandedSlot
        let previousChoice = session.focusedChoice

        // Só repassa o cursor quando ele se move, para não desfazer o foco dado pelo teclado.
        let location = NSEvent.mouseLocation
        if location != lastPointerLocation && (!model.isLatched || panel.frame.contains(location)) {
            lastPointerLocation = location
            session.pointerMoved(dx: location.x - ringCenter.x, dy: -(location.y - ringCenter.y), at: now)
        }
        session.advance(to: now)

        if session.focusedSlot != previousFocus
            || session.expandedSlot != previousExpansion
            || session.focusedChoice != previousChoice {
            lastInteractionAt = now
        }
        syncModel()
    }

    private func syncModel() {
        model.focusedRank = session.focusedSlot
        model.expandedRank = session.expandedSlot
        model.focusedChoice = session.focusedChoice
        model.armingProgress = session.armingProgress(at: now)
        model.wouldCancel = session.wouldCancelOnRelease
        if let rank = session.expandedSlot, let index = session.focusedChoice, index != announcedChoice,
           let choice = model.choices[rank]?[index] {
            announce("\(choice.title), \(choice.isActive ? "connected" : "not connected")")
        }
        announcedChoice = session.focusedChoice
        if let focused = session.focusedSlot, focused != announcedFocus,
           let item = model.slots.first(where: { $0.rank == focused })?.item {
            announce("\(item.title), \(item.state.statusSubtitle)")
        }
        announcedFocus = session.focusedSlot
    }

    private func registerTransientKeys(latched: Bool) {
        unregisterTransientKeys()
        let center = RingHotKeyCenter.shared
        var identifiers: [UInt32?] = []

        identifiers.append(center.register(keyCode: kVK_Escape, modifiers: 0, onPress: { [weak self] in
            self?.escapePressed()
        }))
        identifiers.append(center.register(keyCode: kVK_Escape, modifiers: Self.triggerModifiers, onPress: { [weak self] in
            self?.escapePressed()
        }))

        if latched {
            identifiers.append(center.register(keyCode: kVK_Tab, modifiers: 0, onPress: { [weak self] in
                guard let self else { return }
                self.lastInteractionAt = self.now
                self.session.toggleExpansion()
                self.syncModel()
            }))
            for (rank, keyCode) in Self.digitKeyCodes.enumerated() {
                identifiers.append(center.register(keyCode: keyCode, modifiers: 0, onPress: { [weak self] in
                    self?.digitPressed(rank)
                }))
            }
            for keyCode in [kVK_Return, kVK_ANSI_KeypadEnter] {
                identifiers.append(center.register(keyCode: keyCode, modifiers: 0, onPress: { [weak self] in
                    guard let self else { return }
                    self.handle(self.session.confirm(at: self.now))
                }))
            }
            for (keyCode, clockwise) in [(kVK_RightArrow, true), (kVK_DownArrow, true), (kVK_LeftArrow, false), (kVK_UpArrow, false)] {
                identifiers.append(center.register(keyCode: keyCode, modifiers: 0, onPress: { [weak self] in
                    guard let self else { return }
                    self.lastInteractionAt = self.now
                    self.session.rotateFocus(clockwise: clockwise, at: self.now)
                    self.syncModel()
                }))
            }
        }
        transientHotKeyIDs = identifiers.compactMap { $0 }
    }

    /// Esc com o leque aberto volta ao anel; sem leque, fecha.
    private func escapePressed() {
        lastInteractionAt = now
        if session.expandedSlot != nil {
            session.collapse()
            syncModel()
        } else {
            handle(session.cancel())
        }
    }

    private func digitPressed(_ rank: Int) {
        lastInteractionAt = now
        if session.expandedSlot != nil {
            session.select(choice: rank)
            handle(session.confirm(at: now))
            return
        }
        if session.focusedSlot != rank {
            session.select(slot: rank, at: now)
        }
        handle(session.confirm(at: now))
    }

    private func unregisterTransientKeys() {
        for identifier in transientHotKeyIDs {
            RingHotKeyCenter.shared.unregister(identifier)
        }
        transientHotKeyIDs = []
    }

    private func stopInput() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        unregisterTransientKeys()
        for monitor in mouseMonitors {
            NSEvent.removeMonitor(monitor)
        }
        mouseMonitors = []
        panel.ignoresMouseEvents = true
    }

    // MARK: - Helpers

    private var now: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    private static func isActionable(_ state: SwitchExecutionState) -> Bool {
        switch state {
        case .unsupported, .busy:
            return false
        case .on, .off, .permissionRequired:
            return true
        }
    }

    private func announce(_ message: String) {
        NSAccessibility.post(
            element: NSApp as Any,
            notification: .announcementRequested,
            userInfo: [
                .announcement: message,
                .priority: NSAccessibilityPriorityLevel.high.rawValue
            ]
        )
    }
}
