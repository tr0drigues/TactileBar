import SwiftUI
import TactileCore

public struct TactileSwitchCardView: View {
    let item: any TactileSwitchProtocol
    let onTrigger: () -> Void

    public init(
        item: any TactileSwitchProtocol,
        onTrigger: @escaping () -> Void
    ) {
        self.item = item
        self.onTrigger = onTrigger
    }

    private var domainAccent: Color {
        TactilePalette.accentColor(for: item.domain)
    }

    private var isSwitchActive: Bool {
        item.state.isEnabled
    }

    public var body: some View {
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

                Spacer(minLength: 4)

                // Right Tactile Control (Toggle Pill vs Momentary Pulse Button)
                TactileTogglePillView(
                    isOn: isSwitchActive,
                    isMomentary: item.isMomentaryAction,
                    accentColor: domainAccent
                )
            }
            .padding(.horizontal, 10)
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(item.id) · \(item.title) (\(item.subsystemLabel))")
    }
}

public struct TactileTogglePillView: View {
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
