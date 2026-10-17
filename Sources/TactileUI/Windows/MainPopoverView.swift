import AppKit
import SwiftUI
import TactileCore

public struct MainPopoverView: View {
    @Bindable var registry: SwitchRegistry

    private let releaseChecker = GitHubReleaseChecker()
    private let gridColumns = [
        GridItem(.flexible(), spacing: AppConfiguration.LayoutMetrics.gridSpacing),
        GridItem(.flexible(), spacing: AppConfiguration.LayoutMetrics.gridSpacing)
    ]

    public init(registry: SwitchRegistry) {
        self.registry = registry
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerSection
            domainFilterBar
            Divider().overlay(TactilePalette.gridLine)
            switchGridSection
            Divider().overlay(TactilePalette.gridLine)
            footerSection
        }
        .frame(
            width: AppConfiguration.LayoutMetrics.popoverWidth,
            height: AppConfiguration.LayoutMetrics.popoverHeight
        )
        .background(TactilePalette.obsidianBackground)
        .sheet(isPresented: $registry.isShowingSupportSheet) {
            SupportAndAboutSheet(
                totalTriggerCount: registry.totalTriggerCount,
                onDismiss: { registry.isShowingSupportSheet = false }
            )
        }
        .task {
            await registry.refreshAll()
            registry.availableUpdate = await releaseChecker.checkForUpdate()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TACTILE TELEMETRY // INSTRUMENT PANEL")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.tungstenAmber)

                    Text(AppConfiguration.applicationName.uppercased())
                        .font(.system(size: 20, weight: .heavy, design: .default))
                        .tracking(1.2)
                        .foregroundStyle(TactilePalette.ivoryText)
                }

                Spacer()

                HStack(spacing: 8) {
                    Text(String(format: "ACTIVE %02d/%02d", registry.activeSwitchCount, registry.switches.count))
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(TactilePalette.graphitePanel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(TactilePalette.gridLine, lineWidth: 1)
                                )
                        )
                        .foregroundStyle(TactilePalette.oscilloscopeCyan)

                    Button {
                        Task { await registry.refreshAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(TactilePalette.silverMuted)
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(TactilePalette.graphitePanel)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Sincronizar estado de todos os 26 módulos")
                }
            }

            // Filter Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(TactilePalette.slateDim)

                TextField("FILTER TELEMETRY (EX: SW.01, AUDIO, DARK, XCODE)...", text: $registry.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(TactilePalette.ivoryText)

                if !registry.searchQuery.isEmpty {
                    Button {
                        registry.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(TactilePalette.slateDim)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(TactilePalette.graphitePanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(TactilePalette.gridLine, lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var domainFilterBar: some View {
        HStack(spacing: 6) {
            domainTabButton(label: "ALL (26)", domain: nil, accent: TactilePalette.ivoryText)

            ForEach(SwitchDomain.allCases) { domain in
                domainTabButton(
                    label: domain.shortCode,
                    domain: domain,
                    accent: TactilePalette.accentColor(for: domain)
                )
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func domainTabButton(label: String, domain: SwitchDomain?, accent: Color) -> some View {
        let isSelected = registry.selectedDomainFilter == domain
        return Button {
            registry.selectedDomainFilter = domain
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isSelected ? accent.opacity(0.2) : TactilePalette.graphitePanel)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(isSelected ? accent : TactilePalette.gridLine, lineWidth: 1)
                )
                .foregroundStyle(isSelected ? accent : TactilePalette.silverMuted)
        }
        .buttonStyle(.plain)
    }

    private var switchGridSection: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: AppConfiguration.LayoutMetrics.gridSpacing) {
                ForEach(registry.filteredSwitches, id: \.id) { item in
                    TactileSwitchCardView(item: item) {
                        Task {
                            await registry.triggerSwitch(withID: item.id)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var footerSection: some View {
        HStack(spacing: 12) {
            Button {
                registry.isShowingSupportSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(TactilePalette.tungstenAmber)
                    Text("SUPPORT CRAFTSMANSHIP ☕")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.ivoryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(TactilePalette.graphitePanel)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(TactilePalette.tungstenAmber.opacity(0.6), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            if let update = registry.availableUpdate {
                Button {
                    NSWorkspace.shared.open(update.releasePageURL)
                } label: {
                    Text("UPDATE v\(update.latestVersion)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(TactilePalette.signalEmerald.opacity(0.2))
                        )
                        .foregroundStyle(TactilePalette.signalEmerald)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text("v\(AppConfiguration.currentVersion)")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(TactilePalette.slateDim)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("QUIT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.internationalOrange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(TactilePalette.gridLine, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(TactilePalette.obsidianBackground)
    }
}
