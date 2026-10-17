import AppKit
import SwiftUI
import TactileCore

public struct SupportAndAboutSheet: View {
    let totalTriggerCount: Int
    let onDismiss: () -> Void

    public init(totalTriggerCount: Int, onDismiss: @escaping () -> Void) {
        self.totalTriggerCount = totalTriggerCount
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TACTILE TELEMETRY // SUPPORT CRAFTSMANSHIP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.tungstenAmber)

                    Text("\(AppConfiguration.applicationName) v\(AppConfiguration.currentVersion)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(TactilePalette.ivoryText)
                }

                Spacer()

                Button(action: onDismiss) {
                    HStack(spacing: 5) {
                        Text("CLOSE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(TactilePalette.ivoryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(TactilePalette.obsidianBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(TactilePalette.borderSteel, lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }

            Rectangle()
                .fill(TactilePalette.gridLine)
                .frame(height: 1)

            HStack(alignment: .center, spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(TactilePalette.ivoryText)
                        .frame(width: 136, height: 136)

                    if let qrCGImage = QRCodeGeneratorService.generateCGImage(from: AppConfiguration.sponsorURL, dimension: 120) {
                        Image(decorative: qrCGImage, scale: 1.0)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 118, height: 118)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Open-Source Clean-Room Architecture")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TactilePalette.ivoryText)

                    Text("Desenvolvido de forma independente em Swift 6 com 26 módulos nativos. Se esta ferramenta economiza o seu tempo no dia a dia, apoie o projeto via GitHub Sponsors.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(TactilePalette.silverMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button {
                            NSWorkspace.shared.open(AppConfiguration.sponsorURL)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                Text("GITHUB SPONSORS")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(TactilePalette.tungstenAmber)
                            )
                            .foregroundStyle(TactilePalette.obsidianBackground)
                        }
                        .buttonStyle(.plain)

                        Button {
                            NSWorkspace.shared.open(AppConfiguration.githubRepositoryURL)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                Text("GITHUB REPO")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(TactilePalette.borderSteel, lineWidth: 1)
                            )
                            .foregroundStyle(TactilePalette.ivoryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Rectangle()
                .fill(TactilePalette.gridLine)
                .frame(height: 1)

            HStack {
                Text("TELEMETRY // ACIONAMENTOS TOTAIS: \(totalTriggerCount)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(TactilePalette.oscilloscopeCyan)

                Spacer()

                Text("MIT LICENSE // ZERO EXTERNAL DEPENDENCIES")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(TactilePalette.slateDim)
            }
        }
        .padding(20)
        .frame(width: 488)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(TactilePalette.graphitePanel)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(TactilePalette.tungstenAmber.opacity(0.65), lineWidth: 1.3)
                )
        )
        .shadow(color: .black.opacity(0.65), radius: 24, x: 0, y: 10)
    }
}
