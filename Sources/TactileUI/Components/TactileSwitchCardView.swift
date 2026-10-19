import SwiftUI
import TactileCore

public struct TactileSwitchCardView: View {
    let item: any TactileSwitchProtocol
    let isPinned: Bool
    let onTrigger: () -> Void
    let onTogglePin: () -> Void

    public init(
        item: any TactileSwitchProtocol,
        isPinned: Bool = false,
        onTrigger: @escaping () -> Void,
        onTogglePin: @escaping () -> Void = {}
    ) {
        self.item = item
        self.isPinned = isPinned
        self.onTrigger = onTrigger
        self.onTogglePin = onTogglePin
    }

    private var domainAccent: Color {
        TactilePalette.accentColor(for: item.domain)
    }

    private var isSwitchActive: Bool {
        item.state.isEnabled
    }

    public var body: some View {
        HStack(spacing: 8) {
            Button(action: onTrigger) {
                HStack(spacing: 10) {
                    // Left Horological Bezel + Bespoke Vector Schematic (36x36pt)
                    TactileVectorIconView(
                        switchID: item.id,
                        isActive: isSwitchActive,
                        accentColor: domainAccent,
                        dimension: 36.0
                    )

                    // Center Human-Centric Title & Status (No API Noise)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 11.5, weight: .bold, design: .default))
                            .tracking(0.3)
                            .foregroundStyle(TactilePalette.ivoryText)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Circle()
                                .fill(isSwitchActive ? domainAccent : TactilePalette.slateDim.opacity(0.6))
                                .frame(width: 5, height: 5)

                            Text(item.state.statusSubtitle)
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(isSwitchActive ? domainAccent : TactilePalette.silverMuted)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 2)

                    // Right Tactile Control (Toggle Pill vs Momentary Pulse Button)
                    TactileTogglePillView(
                        isOn: isSwitchActive,
                        isMomentary: item.isMomentaryAction,
                        accentColor: domainAccent
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(item.title)
            .accessibilityValue("\(item.state.statusSubtitle), \(isSwitchActive ? "Active" : "Inactive")")
            .accessibilityAddTraits(.isButton)

            Button(action: onTogglePin) {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 9.5, weight: .bold))
                    .rotationEffect(.degrees(isPinned ? 0 : 45))
                    .foregroundStyle(
                        isPinned
                            ? TactilePalette.tungstenAmber
                            : TactilePalette.slateDim.opacity(0.55)
                    )
                    .frame(width: 18, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPinned ? "Unpin \(item.title)" : "Pin \(item.title) to Pinned Deck")
            .help(isPinned ? "Unpin from Pinned Deck (★ PIN)" : "Pin to Pinned Deck (★ PIN)")
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 52, maxHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: AppConfiguration.LayoutMetrics.cardCornerRadius)
                .fill(isSwitchActive ? TactilePalette.elevatedPanel : TactilePalette.graphitePanel)
        )
        .overlay(alignment: .leading) {
            if isSwitchActive {
                UnevenRoundedRectangle(
                    topLeadingRadius: AppConfiguration.LayoutMetrics.cardCornerRadius,
                    bottomLeadingRadius: AppConfiguration.LayoutMetrics.cardCornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(domainAccent)
                .frame(width: 3)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppConfiguration.LayoutMetrics.cardCornerRadius)
                .strokeBorder(
                    isSwitchActive ? domainAccent.opacity(0.65) : TactilePalette.gridLine,
                    lineWidth: isSwitchActive ? 1.2 : 0.9
                )
        )
        .contextMenu {
            Button {
                onTogglePin()
            } label: {
                Label(
                    isPinned ? "Unpin from Pinned Deck (PIN)" : "Pin to Pinned Deck (PIN)",
                    systemImage: isPinned ? "pin.slash" : "pin.fill"
                )
            }
            Divider()
            Button {
                onTrigger()
            } label: {
                Label(
                    item.isMomentaryAction ? "Run \(item.title)" : "Toggle \(item.title)",
                    systemImage: "power"
                )
            }
        }
        .help("\(item.id) · \(item.title) (\(item.subsystemLabel)) — Right-click or click pin icon to pin/unpin")
    }
}

public struct TactileTogglePillView: View, Equatable {
    let isOn: Bool
    let isMomentary: Bool
    let accentColor: Color

    public var body: some View {
        if isMomentary {
            // Momentary Pulse Action Affordance (Distinguishes one-shot actions from toggles)
            HStack(spacing: 2) {
                Text("RUN")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                Image(systemName: "play.fill")
                    .font(.system(size: 6.5, weight: .bold))
            }
            .foregroundStyle(TactilePalette.silverMuted)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(TactilePalette.obsidianBackground)
                    .overlay(
                        Capsule()
                            .strokeBorder(TactilePalette.borderSteel, lineWidth: 0.9)
                    )
            )
        } else {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? accentColor.opacity(0.24) : TactilePalette.obsidianBackground)
                    .frame(width: 30, height: 16)
                    .overlay(
                        Capsule()
                            .strokeBorder(isOn ? accentColor : TactilePalette.gridLine, lineWidth: 1.0)
                    )

                Circle()
                    .fill(isOn ? accentColor : TactilePalette.slateDim)
                    .frame(width: 10, height: 10)
                    .padding(.horizontal, 3)
            }
            .animation(.snappy(duration: 0.18), value: isOn)
        }
    }
}
