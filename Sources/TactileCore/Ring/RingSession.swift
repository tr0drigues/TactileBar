import Foundation

public struct RingTiming: Equatable, Sendable {
    /// Toque rápido abaixo deste tempo, sem foco, deixa o anel fixo aberto.
    public var latchThreshold: TimeInterval
    /// Soltar com foco antes deste tempo é tratado como acidente e cancela.
    public var minimumOpenDuration: TimeInterval
    /// Tempo parado sobre um switch destrutivo até ele ficar armado.
    public var armDwell: TimeInterval
    /// Tempo parado sobre uma fatia com escolhas até o leque abrir.
    public var expandDwell: TimeInterval

    public init(
        latchThreshold: TimeInterval,
        minimumOpenDuration: TimeInterval,
        armDwell: TimeInterval,
        expandDwell: TimeInterval = 0.40
    ) {
        self.latchThreshold = latchThreshold
        self.minimumOpenDuration = minimumOpenDuration
        self.armDwell = armDwell
        self.expandDwell = expandDwell
    }

    public static let standard = RingTiming(latchThreshold: 0.25, minimumOpenDuration: 0.15, armDwell: 0.30, expandDwell: 0.40)
}

public struct RingSlotEntry: Equatable, Sendable {
    public let switchID: String
    public let isDestructive: Bool
    public let isActionable: Bool
    /// IDs das escolhas do leque, na ordem exibida. Vazio = fatia simples.
    public let choiceIDs: [String]

    public init(switchID: String, isDestructive: Bool, isActionable: Bool, choiceIDs: [String] = []) {
        self.switchID = switchID
        self.isDestructive = isDestructive
        self.isActionable = isActionable
        self.choiceIDs = Array(choiceIDs.prefix(RingGeometry.maxChoices))
    }
}

public enum RingPhase: Equatable, Sendable {
    case closed
    /// Atalho segurado: soltar aciona a fatia em foco.
    case holding
    /// Toque rápido: anel fixo, aciona por clique, Enter ou 1–8.
    case latched
}

public enum RingOutcome: Equatable, Sendable {
    case none
    case fire(switchID: String)
    /// Escolha específica dentro do leque de um switch.
    case fireChoice(switchID: String, choiceID: String)
    case dismiss
}

/// Máquina de estados do anel, sem AppKit. O tempo é sempre injetado.
public struct RingSession: Sendable {
    public private(set) var phase: RingPhase = .closed
    public private(set) var focusedSlot: Int?
    public private(set) var slots: [RingSlotEntry?] = []
    /// Fatia cujo leque de escolhas está aberto.
    public private(set) var expandedSlot: Int?
    /// Escolha em foco dentro do leque aberto.
    public private(set) var focusedChoice: Int?
    public let timing: RingTiming
    public let deadZoneRadius: Double
    /// Distância a partir da qual o cursor abre o leque e aponta as escolhas.
    public let expandRadius: Double

    private var openedAt: TimeInterval = 0
    private var focusedAt: TimeInterval = 0
    private var hasLeftDeadZone = false
    /// Depois de fechar o leque com Esc, não reabre por tempo até o foco mudar.
    private var dwellSuppressed = false

    public init(timing: RingTiming = .standard, deadZoneRadius: Double, expandRadius: Double = .infinity) {
        self.timing = timing
        self.deadZoneRadius = deadZoneRadius
        self.expandRadius = expandRadius
    }

    public var isOpen: Bool {
        phase != .closed
    }

    /// Cursor voltou ao centro depois de sair: soltar agora cancela.
    public var wouldCancelOnRelease: Bool {
        phase == .holding && focusedSlot == nil && hasLeftDeadZone
    }

    public mutating func open(slots: [RingSlotEntry?], at now: TimeInterval) {
        self.slots = slots
        phase = .holding
        focusedSlot = nil
        expandedSlot = nil
        focusedChoice = nil
        openedAt = now
        focusedAt = now
        hasLeftDeadZone = false
        dwellSuppressed = false
    }

    public mutating func pointerMoved(dx: Double, dy: Double, at now: TimeInterval) {
        guard isOpen else { return }
        let distance = (dx * dx + dy * dy).squareRoot()
        let pointed = RingGeometry.slot(dx: dx, dy: dy, deadZoneRadius: deadZoneRadius)
        if pointed != nil {
            hasLeftDeadZone = true
        }

        if let expanded = expandedSlot {
            if distance >= expandRadius,
               let choice = RingGeometry.choice(dx: dx, dy: dy, count: choiceCount(expanded), aroundSlot: expanded) {
                focusedChoice = choice
                return
            }
            if pointed == expanded {
                focusedChoice = nil
                return
            }
            expandedSlot = nil
            focusedChoice = nil
        }

        setFocus(pointed.flatMap { isOccupied($0) ? $0 : nil }, at: now)

        // Empurrar além da borda de uma fatia com escolhas abre o leque.
        if let slot = focusedSlot, distance >= expandRadius, choiceCount(slot) > 0 {
            expandedSlot = slot
            focusedChoice = RingGeometry.choice(dx: dx, dy: dy, count: choiceCount(slot), aroundSlot: slot)
        }
    }

    /// Avança o tempo sem mover o cursor: parar sobre uma fatia com escolhas abre o leque.
    public mutating func advance(to now: TimeInterval) {
        guard isOpen, expandedSlot == nil, !dwellSuppressed,
              let slot = focusedSlot, choiceCount(slot) > 0,
              now - focusedAt >= timing.expandDwell else { return }
        expandedSlot = slot
        focusedChoice = nil
    }

    public mutating func select(slot: Int, at now: TimeInterval) {
        guard isOpen, isOccupied(slot) else { return }
        if expandedSlot != nil {
            expandedSlot = nil
            focusedChoice = nil
        }
        setFocus(slot, at: now)
    }

    /// Tecla 1–8 com o leque aberto.
    public mutating func select(choice index: Int) {
        guard isOpen, let expanded = expandedSlot, index >= 0, index < choiceCount(expanded) else { return }
        focusedChoice = index
    }

    /// Tab: abre o leque da fatia em foco, ou fecha se já estiver aberto.
    public mutating func toggleExpansion() {
        guard isOpen else { return }
        if expandedSlot != nil {
            collapse()
            return
        }
        guard let slot = focusedSlot, choiceCount(slot) > 0 else { return }
        expandedSlot = slot
        focusedChoice = 0
    }

    /// Fecha o leque e volta ao anel principal, mantendo a fatia em foco.
    public mutating func collapse() {
        guard expandedSlot != nil else { return }
        expandedSlot = nil
        focusedChoice = nil
        dwellSuppressed = true
    }

    public mutating func rotateFocus(clockwise: Bool, at now: TimeInterval) {
        guard isOpen else { return }
        if let expanded = expandedSlot {
            let count = choiceCount(expanded)
            guard count > 0 else { return }
            guard let current = focusedChoice else {
                focusedChoice = clockwise ? 0 : count - 1
                return
            }
            focusedChoice = (current + (clockwise ? 1 : count - 1)) % count
            return
        }
        let order = RingGeometry.clockwiseOrder.filter { isOccupied($0) }
        guard !order.isEmpty else { return }
        guard let current = focusedSlot, let index = order.firstIndex(of: current) else {
            setFocus(clockwise ? order.first : order.last, at: now)
            return
        }
        let step = clockwise ? 1 : order.count - 1
        setFocus(order[(index + step) % order.count], at: now)
    }

    /// 0...1 para switch destrutivo em foco; 1 para todos os demais.
    public func armingProgress(at now: TimeInterval) -> Double {
        guard let slot = focusedSlot, let entry = slots[slot], entry.isDestructive else { return 1 }
        guard timing.armDwell > 0 else { return 1 }
        return min(1, max(0, (now - focusedAt) / timing.armDwell))
    }

    public mutating func hotKeyReleased(at now: TimeInterval) -> RingOutcome {
        guard phase == .holding else { return .none }
        let elapsed = now - openedAt
        if focusedSlot == nil {
            if !hasLeftDeadZone && elapsed < timing.latchThreshold {
                phase = .latched
                return .none
            }
            return close()
        }
        if elapsed < timing.minimumOpenDuration {
            return close()
        }
        return fireFocused(at: now, cancelIfNotReady: true)
    }

    /// Clique ou Enter no modo fixo. Sem foco, fecha.
    public mutating func confirm(at now: TimeInterval) -> RingOutcome {
        guard isOpen else { return .none }
        guard focusedSlot != nil else { return close() }
        return fireFocused(at: now, cancelIfNotReady: false)
    }

    public mutating func cancel() -> RingOutcome {
        guard isOpen else { return .none }
        return close()
    }

    private mutating func fireFocused(at now: TimeInterval, cancelIfNotReady: Bool) -> RingOutcome {
        guard let slot = focusedSlot, let entry = slots[slot] else { return close() }
        guard entry.isActionable, armingProgress(at: now) >= 1 else {
            return cancelIfNotReady ? close() : .none
        }
        let choice = expandedSlot == slot ? focusedChoice : nil
        reset()
        if let choice, entry.choiceIDs.indices.contains(choice) {
            return .fireChoice(switchID: entry.switchID, choiceID: entry.choiceIDs[choice])
        }
        return .fire(switchID: entry.switchID)
    }

    private mutating func close() -> RingOutcome {
        reset()
        return .dismiss
    }

    private mutating func reset() {
        phase = .closed
        focusedSlot = nil
        expandedSlot = nil
        focusedChoice = nil
        slots = []
        hasLeftDeadZone = false
        dwellSuppressed = false
    }

    private mutating func setFocus(_ slot: Int?, at now: TimeInterval) {
        if slot != focusedSlot {
            focusedSlot = slot
            focusedAt = now
            dwellSuppressed = false
        }
    }

    private func isOccupied(_ slot: Int) -> Bool {
        slots.indices.contains(slot) && slots[slot] != nil
    }

    private func choiceCount(_ slot: Int) -> Int {
        guard slots.indices.contains(slot), let entry = slots[slot] else { return 0 }
        return entry.choiceIDs.count
    }
}
