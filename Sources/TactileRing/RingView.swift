import AppKit
import Observation
import SwiftUI
import TactileCore
import TactileUI

enum RingMetrics {
    static let panelSize = NSSize(width: 760, height: 500)
    static let bezelRadius: CGFloat = 146
    static let calibrationRadius: CGFloat = 131
    static let sliceOuterRadius: CGFloat = 125
    static let sliceInnerRadius: CGFloat = 74
    static let innerCalibrationRadius: CGFloat = 70
    static let focusPush: CGFloat = 6
    static let focusOuterBoost: CGFloat = 3
    static let iconRadius: CGFloat = 100
    static let keyRadius: CGFloat = 83
    static let ledRadius: CGFloat = 137
    static let labelRadius: CGFloat = 166
    static let focusedLabelRadius: CGFloat = 172
    static let coreRadius: CGFloat = 53
    static let deadZoneRadius: CGFloat = 59
    static let sliceGapDegrees: Double = 1.6
    static let iconDimension: CGFloat = 26
    static let labelWidth: CGFloat = 150

    // Leque de escolhas por fora da fatia.
    static let choiceExpandRadius: CGFloat = 133
    static let choiceRailRadius: CGFloat = 135
    static let choiceInnerRadius: CGFloat = 141
    static let choiceOuterRadius: CGFloat = 178
    static let choiceFocusBoost: CGFloat = 5
    static let choiceKeyRadius: CGFloat = 151
    static let choiceLedRadius: CGFloat = 169
    static let choiceLabelRadius: CGFloat = 192
    static let choiceGapDegrees: Double = 0.9
    static let choiceLabelWidth: CGFloat = 130
    static let dimmedOpacity: Double = 0.32
}

/// Estado exibido pelo anel; o `RingController` é quem o atualiza.
@Observable
@MainActor
final class RingViewModel {
    struct Slot: Identifiable {
        let rank: Int
        let item: any TactileSwitchProtocol
        let isDestructive: Bool
        var id: Int { rank }
    }

    var slots: [Slot] = []
    var emptyRanks: [Int] = []
    var focusedRank: Int?
    var armingProgress: Double = 1
    var isLatched = false
    var wouldCancel = false
    var executingRank: Int?
    var overflowCount = 0

    /// Escolhas por rank (até 8) e quantas ficaram de fora.
    var choices: [Int: [RingChoice]] = [:]
    var choiceOverflow: [Int: Int] = [:]
    var expandedRank: Int?
    var focusedChoice: Int?
    var executingChoice: Int?

    func dimming(rank: Int) -> Double {
        guard let expandedRank, expandedRank != rank else { return 1 }
        return RingMetrics.dimmedOpacity
    }
}

struct RingView: View {
    let model: RingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var center: CGPoint {
        CGPoint(x: RingMetrics.panelSize.width / 2, y: RingMetrics.panelSize.height / 2)
    }

    var body: some View {
        let snapshot = DrawSnapshot(model: model)
        ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: snapshot.executingRank == nil || reduceMotion)) { timeline in
                let phase = reduceMotion ? 0 : CGFloat(timeline.date.timeIntervalSinceReferenceDate * 24).truncatingRemainder(dividingBy: 10)
                Canvas { context, _ in
                    RingDrawing.draw(in: &context, center: center, snapshot: snapshot, dashPhase: phase)
                }
            }

            ForEach(model.slots) { slot in
                slotOverlay(slot)
                    .opacity(model.dimming(rank: slot.rank))
            }

            if let rank = model.expandedRank, let choices = model.choices[rank] {
                choiceOverlays(rank: rank, choices: choices)
            }

            coreLabels
        }
        .frame(width: RingMetrics.panelSize.width, height: RingMetrics.panelSize.height)
        .accessibilityHidden(true)
    }

    // MARK: - Overlays

    @ViewBuilder
    private func choiceOverlays(rank: Int, choices: [RingChoice]) -> some View {
        let angles = RingGeometry.choiceAngles(count: choices.count, aroundSlot: rank)
        let accent = model.slots.first(where: { $0.rank == rank }).map { TactilePalette.accentColor(for: $0.item.domain) }
            ?? TactilePalette.signalEmerald
        let activeIndex = model.executingChoice ?? model.focusedChoice

        ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
            let isFocused = activeIndex == index
            let isExecuting = model.executingChoice == index
            let boost = isFocused ? RingMetrics.choiceFocusBoost : 0

            Text("\(index + 1)")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(isFocused || model.isLatched ? TactilePalette.ivoryText : TactilePalette.silverMuted)
                .position(point(angle: angles[index], radius: RingMetrics.choiceKeyRadius))

            choiceLabel(
                choice,
                angle: angles[index],
                radius: RingMetrics.choiceLabelRadius + boost,
                isFocused: isFocused,
                isExecuting: isExecuting,
                accent: accent
            )
        }

        if let overflow = model.choiceOverflow[rank], overflow > 0, let last = angles.last {
            Text("+\(overflow)")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundStyle(TactilePalette.silverMuted)
                .position(point(angle: last + RingGeometry.choiceSpan * 0.85, radius: RingMetrics.choiceKeyRadius + 8))
        }
    }

    private func choiceLabel(
        _ choice: RingChoice,
        angle: Double,
        radius: CGFloat,
        isFocused: Bool,
        isExecuting: Bool,
        accent: Color
    ) -> some View {
        let anchor = point(angle: angle, radius: radius)
        let radians = angle * Double.pi / 180.0
        let horizontal = cos(radians)
        let vertical = sin(radians)
        let alignment: HorizontalAlignment = horizontal > 0.2 ? .leading : (horizontal < -0.2 ? .trailing : .center)
        let frameAlignment: Alignment = horizontal > 0.2 ? .leading : (horizontal < -0.2 ? .trailing : .center)
        let halfWidth = RingMetrics.choiceLabelWidth / 2
        let x = horizontal > 0.2 ? anchor.x + halfWidth : (horizontal < -0.2 ? anchor.x - halfWidth : anchor.x)
        let y = vertical < -0.6 ? anchor.y - 11 : (vertical > 0.6 ? anchor.y + 11 : anchor.y)

        var status = "\(choice.badge) · \(choice.isActive ? "ON" : "OFF")"
        if choice.isPreferred {
            status += " · PREF"
        }
        if isExecuting {
            status = choice.isActive ? "DISCONNECTING..." : "LINKING..."
        }

        return VStack(alignment: alignment, spacing: 1) {
            Text(choice.title)
                .font(.system(size: isFocused ? 10.5 : 9.5, weight: isFocused ? .bold : .semibold))
                .tracking(0.3)
                .foregroundStyle(isFocused ? TactilePalette.ivoryText : TactilePalette.silverMuted)
            Text(status)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(isFocused || choice.isActive ? accent : TactilePalette.slateDim)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .frame(width: RingMetrics.choiceLabelWidth, alignment: frameAlignment)
        .position(x: x, y: y)
    }

    @ViewBuilder
    private func slotOverlay(_ slot: Slot) -> some View {
        let isFocused = model.focusedRank == slot.rank
        let accent = TactilePalette.accentColor(for: slot.item.domain)
        let isLit = isFocused || slot.item.state.isEnabled
        let push = isFocused ? RingMetrics.focusPush : 0

        TactileVectorIconView(
            switchID: slot.item.id,
            isActive: isLit,
            accentColor: accent,
            dimension: RingMetrics.iconDimension
        )
        .position(point(rank: slot.rank, radius: RingMetrics.iconRadius + push))

        Text("\(slot.rank + 1)")
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(isFocused ? TactilePalette.ivoryText : TactilePalette.silverMuted)
            .position(point(rank: slot.rank, radius: RingMetrics.keyRadius + push))

        if model.expandedRank != slot.rank {
            label(for: slot, isFocused: isFocused, isLit: isLit, accent: accent)
        }
    }

    private func label(for slot: Slot, isFocused: Bool, isLit: Bool, accent: Color) -> some View {
        let radius = isFocused ? RingMetrics.focusedLabelRadius : RingMetrics.labelRadius
        let anchor = point(rank: slot.rank, radius: radius)
        let angle = RingGeometry.slotAngles[slot.rank] * Double.pi / 180.0
        let horizontal = cos(angle)
        let vertical = sin(angle)

        let alignment: HorizontalAlignment = horizontal > 0.2 ? .leading : (horizontal < -0.2 ? .trailing : .center)
        let frameAlignment: Alignment = horizontal > 0.2 ? .leading : (horizontal < -0.2 ? .trailing : .center)
        let halfWidth = RingMetrics.labelWidth / 2
        let x = horizontal > 0.2 ? anchor.x + halfWidth : (horizontal < -0.2 ? anchor.x - halfWidth : anchor.x)
        let y = vertical < -0.6 ? anchor.y - 13 : (vertical > 0.6 ? anchor.y + 13 : anchor.y)

        return VStack(alignment: alignment, spacing: 2) {
            Text(slot.item.title)
                .font(.system(size: 10.5, weight: .bold))
                .tracking(0.3)
                .foregroundStyle(isFocused ? TactilePalette.ivoryText : TactilePalette.silverMuted)
            Text(slot.item.state.statusSubtitle)
                .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(isLit ? accent : TactilePalette.silverMuted)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(width: RingMetrics.labelWidth, alignment: frameAlignment)
        .position(x: x, y: y)
    }

    private var coreLabels: some View {
        let content = coreContent()
        return VStack(spacing: 3) {
            Text(content.top)
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(TactilePalette.silverMuted)
            Text(content.middle)
                .font(content.isCounter
                    ? .system(size: 18, weight: .heavy, design: .monospaced)
                    : .system(size: 11.5, weight: .bold))
                .foregroundStyle(TactilePalette.ivoryText)
            Text(content.bottom)
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(content.bottomColor)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(width: RingMetrics.coreRadius * 1.8)
        .position(center)
    }

    private struct CoreContent {
        let top: String
        let middle: String
        let bottom: String
        let bottomColor: Color
        let isCounter: Bool
    }

    private func coreContent() -> CoreContent {
        if let rank = model.focusedRank ?? model.executingRank,
           let slot = model.slots.first(where: { $0.rank == rank }) {
            let item = slot.item
            let accent = TactilePalette.accentColor(for: item.domain)
            let choices = model.choices[rank] ?? []
            if !choices.isEmpty, let content = choiceCoreContent(item: item, choices: choices, rank: rank, accent: accent) {
                return content
            }
            let top = slot.isDestructive ? "\(item.id) · SEC" : item.id
            if model.executingRank == rank {
                return CoreContent(top: top, middle: item.title, bottom: item.state.statusSubtitle, bottomColor: accent, isCounter: false)
            }
            switch item.state {
            case .unsupported:
                return CoreContent(top: top, middle: item.title, bottom: "UNAVAILABLE", bottomColor: TactilePalette.silverMuted, isCounter: false)
            case .busy:
                return CoreContent(top: top, middle: item.title, bottom: item.state.statusSubtitle, bottomColor: accent, isCounter: false)
            default:
                break
            }
            if slot.isDestructive && model.armingProgress < 1 {
                return CoreContent(top: top, middle: item.title, bottom: "HOLD · ARMING", bottomColor: accent, isCounter: false)
            }
            let verb = model.isLatched ? "CLICK" : "RELEASE"
            let action: String
            if case .permissionRequired = item.state {
                action = "GRANT"
            } else if item.isMomentaryAction {
                action = "RUN ▸"
            } else {
                action = item.state.isEnabled ? "OFF" : "ON"
            }
            return CoreContent(top: top, middle: item.title, bottom: "\(verb) · \(action)", bottomColor: accent, isCounter: false)
        }

        if model.wouldCancel {
            return CoreContent(top: "ESC", middle: "CANCEL", bottom: "RELEASE TO CLOSE", bottomColor: TactilePalette.silverMuted, isCounter: false)
        }

        let total = model.slots.count
        let active = model.slots.filter { $0.item.state.isEnabled }.count
        let overflow = model.overflowCount > 0 ? " +\(model.overflowCount)" : ""
        return CoreContent(
            top: String(format: "%02d PINNED", total) + overflow,
            middle: String(format: "%02d/%02d", active, total),
            bottom: model.isLatched ? "1–8 · ESC" : "ONLINE",
            bottomColor: TactilePalette.tungstenAmber,
            isCounter: true
        )
    }

    /// Núcleo de uma fatia com escolhas. Nil quando o estado do switch pede o texto padrão.
    private func choiceCoreContent(item: any TactileSwitchProtocol, choices: [RingChoice], rank: Int, accent: Color) -> CoreContent? {
        let verb = model.isLatched ? "CLICK" : "RELEASE"
        let preferred = choices.first(where: \.isPreferred) ?? choices.first

        if model.expandedRank == rank {
            let top = "\(item.title) ▸"
            if let index = model.executingChoice ?? model.focusedChoice, choices.indices.contains(index) {
                let choice = choices[index]
                let bottom: String
                if model.executingChoice != nil {
                    bottom = choice.isActive ? "DISCONNECTING..." : "LINKING..."
                } else {
                    bottom = "\(verb) · \(choice.isActive ? "DISCONNECT" : "CONNECT")"
                }
                return CoreContent(top: top, middle: choice.title, bottom: bottom, bottomColor: accent, isCounter: false)
            }
            let bottom = model.isLatched ? "1–\(choices.count) · ESC BACK" : "\(verb) · \(preferred?.title ?? "PREFERRED")"
            return CoreContent(top: top, middle: preferred?.title ?? item.title, bottom: bottom, bottomColor: accent, isCounter: false)
        }

        guard model.executingRank != rank else { return nil }
        switch item.state {
        case .unsupported, .busy, .permissionRequired:
            return nil
        default:
            break
        }
        let hint = model.isLatched ? "TAB" : "▸"
        return CoreContent(
            top: "\(item.id) · \(hint) \(choices.count) OPTIONS",
            middle: item.title,
            bottom: "\(verb) · \(preferred?.title ?? "PREFERRED")",
            bottomColor: accent,
            isCounter: false
        )
    }

    private func point(angle: Double, radius: CGFloat) -> CGPoint {
        let offset = RingGeometry.offset(angle: angle, radius: Double(radius))
        return CGPoint(x: center.x + offset.dx, y: center.y + offset.dy)
    }

    private func point(rank: Int, radius: CGFloat) -> CGPoint {
        let offset = RingGeometry.offset(forSlot: rank, radius: Double(radius))
        return CGPoint(x: center.x + offset.dx, y: center.y + offset.dy)
    }

    private typealias Slot = RingViewModel.Slot
}

// MARK: - Canvas drawing

/// Cópia dos valores lidos no `body`, para o Canvas desenhar sem depender de rastreamento.
struct DrawSnapshot {
    struct SlotStyle {
        let rank: Int
        let accent: Color
        let isOn: Bool
        let isFocused: Bool
        let isUnsupported: Bool
        let isExecuting: Bool
        let isDestructive: Bool
        let hasChoices: Bool
        let opacity: Double
    }

    struct ChoiceStyle {
        let angle: Double
        let isActive: Bool
        let isFocused: Bool
        let isExecuting: Bool
    }

    let slots: [SlotStyle]
    let emptyRanks: [Int]
    let focusedRank: Int?
    let executingRank: Int?
    let armingProgress: Double
    let wouldCancel: Bool
    let expandedRank: Int?
    let choices: [ChoiceStyle]

    @MainActor
    init(model: RingViewModel) {
        slots = model.slots.map { slot in
            let isUnsupported: Bool
            if case .unsupported = slot.item.state {
                isUnsupported = true
            } else {
                isUnsupported = false
            }
            return SlotStyle(
                rank: slot.rank,
                accent: TactilePalette.accentColor(for: slot.item.domain),
                isOn: slot.item.state.isEnabled,
                isFocused: model.focusedRank == slot.rank,
                isUnsupported: isUnsupported,
                isExecuting: model.executingRank == slot.rank && model.executingChoice == nil,
                isDestructive: slot.isDestructive,
                hasChoices: !(model.choices[slot.rank] ?? []).isEmpty,
                opacity: model.dimming(rank: slot.rank)
            )
        }
        expandedRank = model.expandedRank
        if let rank = model.expandedRank, let list = model.choices[rank] {
            let angles = RingGeometry.choiceAngles(count: list.count, aroundSlot: rank)
            let active = model.executingChoice ?? model.focusedChoice
            choices = list.enumerated().map { index, choice in
                ChoiceStyle(
                    angle: angles[index],
                    isActive: choice.isActive,
                    isFocused: active == index,
                    isExecuting: model.executingChoice == index
                )
            }
        } else {
            choices = []
        }
        emptyRanks = model.emptyRanks
        focusedRank = model.focusedRank
        executingRank = model.executingRank
        armingProgress = model.armingProgress
        wouldCancel = model.wouldCancel
    }
}

enum RingDrawing {
    static func draw(in context: inout GraphicsContext, center: CGPoint, snapshot: DrawSnapshot, dashPhase: CGFloat) {
        drawBezel(in: &context, center: center)

        for rank in snapshot.emptyRanks {
            let path = sector(center: center, rank: rank, outer: RingMetrics.sliceOuterRadius, push: 0)
            context.stroke(path, with: .color(TactilePalette.gridLine), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            let mark = offsetPoint(center: center, rank: rank, radius: RingMetrics.iconRadius)
            var plus = Path()
            plus.move(to: CGPoint(x: mark.x - 5, y: mark.y))
            plus.addLine(to: CGPoint(x: mark.x + 5, y: mark.y))
            plus.move(to: CGPoint(x: mark.x, y: mark.y - 5))
            plus.addLine(to: CGPoint(x: mark.x, y: mark.y + 5))
            context.stroke(plus, with: .color(TactilePalette.slateDim), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }

        for slot in snapshot.slots {
            var layer = context
            layer.opacity = slot.opacity
            drawSlot(slot, in: &layer, center: center, snapshot: snapshot, dashPhase: dashPhase)
        }

        let expandedAccent = snapshot.slots.first(where: { $0.rank == snapshot.expandedRank })?.accent
        if let accent = expandedAccent {
            drawChoices(snapshot.choices, accent: accent, in: &context, center: center, dashPhase: dashPhase)
        }

        if let choice = snapshot.choices.first(where: \.isFocused), let accent = expandedAccent {
            var needle = Path()
            needle.move(to: polar(center: center, radius: RingMetrics.coreRadius + 2, radians: choice.angle * Double.pi / 180.0))
            needle.addLine(to: polar(center: center, radius: RingMetrics.choiceInnerRadius - 2, radians: choice.angle * Double.pi / 180.0))
            context.stroke(needle, with: .color(accent), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        } else if let rank = snapshot.focusedRank, let slot = snapshot.slots.first(where: { $0.rank == rank }) {
            let start = offsetPoint(center: center, rank: rank, radius: RingMetrics.coreRadius + 2)
            let end = offsetPoint(center: center, rank: rank, radius: RingMetrics.sliceInnerRadius - 2)
            var needle = Path()
            needle.move(to: start)
            needle.addLine(to: end)
            context.stroke(needle, with: .color(slot.accent), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        }

        drawCore(in: &context, center: center, snapshot: snapshot)
    }

    private static func drawBezel(in context: inout GraphicsContext, center: CGPoint) {
        let bezelRect = circleRect(center: center, radius: RingMetrics.bezelRadius)
        context.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.65), radius: 22, x: 0, y: 12))
            layer.fill(Path(ellipseIn: bezelRect), with: .color(TactilePalette.obsidianBackground))
        }
        context.stroke(Path(ellipseIn: bezelRect), with: .color(TactilePalette.borderSteel), lineWidth: 1.2)

        var crosshair = Path()
        let r = RingMetrics.bezelRadius
        crosshair.move(to: CGPoint(x: center.x - r, y: center.y))
        crosshair.addLine(to: CGPoint(x: center.x + r, y: center.y))
        crosshair.move(to: CGPoint(x: center.x, y: center.y - r))
        crosshair.addLine(to: CGPoint(x: center.x, y: center.y + r))
        context.stroke(crosshair, with: .color(TactilePalette.hairlineSubtle), lineWidth: 0.75)

        var minorTicks = Path()
        for step in 0..<72 {
            let radians = Double(step) * 5.0 * Double.pi / 180.0
            minorTicks.move(to: polar(center: center, radius: 136, radians: radians))
            minorTicks.addLine(to: polar(center: center, radius: 141, radians: radians))
        }
        context.stroke(minorTicks, with: .color(TactilePalette.gridLine), lineWidth: 0.8)

        var majorTicks = Path()
        for rank in 0..<RingGeometry.slotCount {
            let degrees = -90.0 - RingGeometry.slotSpan / 2 + Double(rank) * RingGeometry.slotSpan
            let radians = degrees * Double.pi / 180.0
            majorTicks.move(to: polar(center: center, radius: RingMetrics.calibrationRadius, radians: radians))
            majorTicks.addLine(to: polar(center: center, radius: 144, radians: radians))
        }
        context.stroke(majorTicks, with: .color(TactilePalette.slateDim), lineWidth: 1.2)

        for degrees in [-90.0, 0.0, 90.0, 180.0] {
            let dot = polar(center: center, radius: RingMetrics.bezelRadius + 4, radians: degrees * Double.pi / 180.0)
            context.fill(Path(ellipseIn: circleRect(center: dot, radius: 1.5)), with: .color(TactilePalette.silverMuted))
        }

        for radius in [RingMetrics.calibrationRadius, RingMetrics.innerCalibrationRadius] {
            context.stroke(Path(ellipseIn: circleRect(center: center, radius: radius)), with: .color(TactilePalette.gridLine), lineWidth: 0.85)
        }
    }

    private static func drawSlot(
        _ slot: DrawSnapshot.SlotStyle,
        in context: inout GraphicsContext,
        center: CGPoint,
        snapshot: DrawSnapshot,
        dashPhase: CGFloat
    ) {
        let push = slot.isFocused ? RingMetrics.focusPush : 0
        let outer = RingMetrics.sliceOuterRadius + (slot.isFocused ? RingMetrics.focusOuterBoost : 0)
        let path = sector(center: center, rank: slot.rank, outer: outer, push: push)

        let fill: Color
        let stroke: Color
        if slot.isUnsupported {
            fill = TactilePalette.graphitePanel.opacity(0.5)
            stroke = TactilePalette.hairlineSubtle
        } else if slot.isFocused {
            fill = slot.accent.opacity(0.30)
            stroke = slot.accent
        } else if slot.isOn {
            fill = slot.accent.opacity(0.15)
            stroke = slot.accent.opacity(0.6)
        } else {
            fill = TactilePalette.graphitePanel
            stroke = TactilePalette.gridLine
        }
        context.fill(path, with: .color(fill))
        let dash: [CGFloat] = slot.isExecuting ? [6, 4] : []
        context.stroke(
            path,
            with: .color(slot.isExecuting ? slot.accent : stroke),
            style: StrokeStyle(lineWidth: slot.isFocused || slot.isExecuting ? 1.6 : 1, dash: dash, dashPhase: dashPhase)
        )

        if slot.isOn {
            let led = offsetPoint(center: center, rank: slot.rank, radius: RingMetrics.ledRadius + push)
            context.fill(Path(ellipseIn: circleRect(center: led, radius: 2.2)), with: .color(slot.accent))
        }

        if slot.hasChoices {
            // Marca ▸ na borda: esta fatia abre um leque de escolhas.
            let mid = RingGeometry.slotAngles[slot.rank]
            let shift = RingGeometry.offset(forSlot: slot.rank, radius: Double(push))
            let origin = CGPoint(x: center.x + shift.dx, y: center.y + shift.dy)
            let tip = polar(center: origin, radius: RingMetrics.sliceOuterRadius + 7, radians: mid * Double.pi / 180.0)
            let left = polar(center: origin, radius: RingMetrics.sliceOuterRadius + 2, radians: (mid - 2.4) * Double.pi / 180.0)
            let right = polar(center: origin, radius: RingMetrics.sliceOuterRadius + 2, radians: (mid + 2.4) * Double.pi / 180.0)
            var chevron = Path()
            chevron.move(to: left)
            chevron.addLine(to: tip)
            chevron.addLine(to: right)
            context.stroke(
                chevron,
                with: .color(slot.isFocused ? TactilePalette.ivoryText : slot.accent),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }

        if slot.isFocused && slot.isDestructive {
            let radius = outer + push + 7
            let mid = RingGeometry.slotAngles[slot.rank]
            let start = mid - RingGeometry.slotSpan / 2 + RingMetrics.sliceGapDegrees
            let end = mid + RingGeometry.slotSpan / 2 - RingMetrics.sliceGapDegrees
            var track = Path()
            track.addArc(center: center, radius: radius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
            context.stroke(track, with: .color(TactilePalette.gridLine), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            var progress = Path()
            progress.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(start),
                endAngle: .degrees(start + (end - start) * snapshot.armingProgress),
                clockwise: false
            )
            context.stroke(progress, with: .color(slot.accent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }

    private static func drawChoices(
        _ choices: [DrawSnapshot.ChoiceStyle],
        accent: Color,
        in context: inout GraphicsContext,
        center: CGPoint,
        dashPhase: CGFloat
    ) {
        guard let first = choices.first, let last = choices.last else { return }
        let half = RingGeometry.choiceSpan / 2
        var rail = Path()
        rail.addArc(
            center: center,
            radius: RingMetrics.choiceRailRadius,
            startAngle: .degrees(first.angle - half),
            endAngle: .degrees(last.angle + half),
            clockwise: false
        )
        context.stroke(rail, with: .color(accent.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, dash: [2, 3]))

        for choice in choices {
            let outer = RingMetrics.choiceOuterRadius + (choice.isFocused ? RingMetrics.choiceFocusBoost : 0)
            var path = Path()
            let start = choice.angle - half + RingMetrics.choiceGapDegrees
            let end = choice.angle + half - RingMetrics.choiceGapDegrees
            path.addArc(center: center, radius: outer, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
            path.addArc(center: center, radius: RingMetrics.choiceInnerRadius, startAngle: .degrees(end), endAngle: .degrees(start), clockwise: true)
            path.closeSubpath()

            let fill: Color
            let stroke: Color
            if choice.isFocused {
                fill = accent.opacity(0.30)
                stroke = accent
            } else if choice.isActive {
                fill = accent.opacity(0.13)
                stroke = accent.opacity(0.55)
            } else {
                fill = TactilePalette.graphitePanel
                stroke = TactilePalette.gridLine
            }
            context.fill(path, with: .color(fill))
            context.stroke(
                path,
                with: .color(stroke),
                style: StrokeStyle(lineWidth: choice.isFocused ? 1.6 : 1, dash: choice.isExecuting ? [6, 4] : [], dashPhase: dashPhase)
            )

            let led = polar(center: center, radius: RingMetrics.choiceLedRadius + (choice.isFocused ? 3 : 0), radians: choice.angle * Double.pi / 180.0)
            let ledRect = circleRect(center: led, radius: 2.2)
            if choice.isActive {
                context.fill(Path(ellipseIn: ledRect), with: .color(accent))
            } else {
                context.stroke(Path(ellipseIn: ledRect), with: .color(TactilePalette.borderSteel), lineWidth: 0.8)
            }
        }
    }

    private static func drawCore(in context: inout GraphicsContext, center: CGPoint, snapshot: DrawSnapshot) {
        let coreRect = circleRect(center: center, radius: RingMetrics.coreRadius)
        context.fill(Path(ellipseIn: coreRect), with: .color(TactilePalette.graphitePanel))

        let focusedAccent = snapshot.slots.first(where: { $0.rank == (snapshot.focusedRank ?? snapshot.executingRank) })?.accent
        if snapshot.wouldCancel {
            context.stroke(Path(ellipseIn: coreRect), with: .color(TactilePalette.ivoryText), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
        } else {
            let color = focusedAccent?.opacity(0.85) ?? TactilePalette.tungstenAmber.opacity(0.75)
            context.stroke(Path(ellipseIn: coreRect), with: .color(color), lineWidth: 1.2)
        }

        context.stroke(
            Path(ellipseIn: circleRect(center: center, radius: RingMetrics.deadZoneRadius)),
            with: .color(TactilePalette.gridLine),
            style: StrokeStyle(lineWidth: 0.8, dash: [2, 4])
        )
    }

    // MARK: - Geometry helpers

    private static func sector(center: CGPoint, rank: Int, outer: CGFloat, push: CGFloat) -> Path {
        let mid = RingGeometry.slotAngles[rank]
        let start = mid - RingGeometry.slotSpan / 2 + RingMetrics.sliceGapDegrees
        let end = mid + RingGeometry.slotSpan / 2 - RingMetrics.sliceGapDegrees
        let shift = RingGeometry.offset(forSlot: rank, radius: Double(push))
        let origin = CGPoint(x: center.x + shift.dx, y: center.y + shift.dy)
        var path = Path()
        path.addArc(center: origin, radius: outer, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        path.addArc(center: origin, radius: RingMetrics.sliceInnerRadius, startAngle: .degrees(end), endAngle: .degrees(start), clockwise: true)
        path.closeSubpath()
        return path
    }

    private static func offsetPoint(center: CGPoint, rank: Int, radius: CGFloat) -> CGPoint {
        let offset = RingGeometry.offset(forSlot: rank, radius: Double(radius))
        return CGPoint(x: center.x + offset.dx, y: center.y + offset.dy)
    }

    private static func polar(center: CGPoint, radius: CGFloat, radians: Double) -> CGPoint {
        CGPoint(x: center.x + CGFloat(cos(radians)) * radius, y: center.y + CGFloat(sin(radians)) * radius)
    }

    private static func circleRect(center: CGPoint, radius: CGFloat) -> CGRect {
        CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    }
}
