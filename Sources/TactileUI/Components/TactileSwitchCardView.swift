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
            VStack(alignment: .leading, spacing: 0) {
                // Top Telemetry Header Bar
                HStack(spacing: 6) {
                    Text(item.id)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(isSwitchActive ? domainAccent : TactilePalette.silverMuted)

                    Text("M.\(item.domain.shortCode)")
                        .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(TactilePalette.slateDim)

                    Spacer()

                    TactileTogglePillView(
                        isOn: isSwitchActive,
                        isMomentary: item.isMomentaryAction,
                        accentColor: domainAccent
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 8)

                Rectangle()
                    .fill(TactilePalette.hairlineSubtle)
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                // Center Horological Instrument Bezel
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(TactilePalette.obsidianBackground)
                            .frame(width: 48, height: 48)
                        Circle()
                            .strokeBorder(
                                isSwitchActive ? domainAccent.opacity(0.85) : TactilePalette.gridLine,
                                lineWidth: isSwitchActive ? 1.6 : 1.0
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: item.sfSymbolName)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(isSwitchActive ? domainAccent : TactilePalette.ivoryText)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)

                Rectangle()
                    .fill(TactilePalette.hairlineSubtle)
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                // Bottom Specification Block
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.system(size: 12.5, weight: .bold, design: .default))
                        .tracking(0.6)
                        .foregroundStyle(TactilePalette.ivoryText)
                        .lineLimit(1)

                    Text("API // \(item.subsystemLabel)")
                        .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(TactilePalette.silverMuted)
                        .lineLimit(1)

                    Text("STATE // \(item.state.statusSubtitle)")
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(isSwitchActive ? domainAccent : TactilePalette.slateDim)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
            }
            .background(
                RoundedRectangle(cornerRadius: AppConfiguration.LayoutMetrics.cardCornerRadius)
                    .fill(TactilePalette.graphitePanel)
            )
            .overlay(alignment: .topLeading) {
                if isSwitchActive {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(domainAccent)
                        .frame(width: 54, height: 2.5)
                        .padding(.leading, 12)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppConfiguration.LayoutMetrics.cardCornerRadius)
                    .strokeBorder(
                        isSwitchActive ? TactilePalette.borderSteel : TactilePalette.gridLine,
                        lineWidth: isSwitchActive ? 1.3 : 1.0
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

public struct TactileTogglePillView: View {
    let isOn: Bool
    let isMomentary: Bool
    let accentColor: Color

    public var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? accentColor.opacity(0.24) : TactilePalette.obsidianBackground)
                .frame(width: 32, height: 16)
                .overlay(
                    Capsule()
                        .strokeBorder(isOn ? accentColor : TactilePalette.gridLine, lineWidth: 1.1)
                )

            Circle()
                .fill(isOn ? accentColor : (isMomentary ? TactilePalette.silverMuted : TactilePalette.slateDim))
                .frame(width: 10, height: 10)
                .padding(.horizontal, 3)
        }
        .animation(.snappy(duration: 0.18), value: isOn)
    }
}
