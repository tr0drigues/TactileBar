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
        ZStack {
            VStack(spacing: 0) {
                headerSection
                domainFilterBar
                Divider().overlay(TactilePalette.gridLine)
                if registry.isShowingRadialDial {
                    TactileTelemetryDialView(registry: registry)
                    Divider().overlay(TactilePalette.gridLine)
                }
                switchGridSection
                Divider().overlay(TactilePalette.gridLine)
                footerSection
            }

            if registry.isShowingSupportSheet {
                Button {
                    registry.isShowingSupportSheet = false
                } label: {
                    Color.black.opacity(0.72)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss support sheet")

                SupportAndAboutSheet(
                    totalTriggerCount: registry.totalTriggerCount,
                    onDismiss: { registry.isShowingSupportSheet = false }
                )
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.16), value: registry.isShowingSupportSheet)
        .frame(
            width: AppConfiguration.LayoutMetrics.popoverWidth,
            height: AppConfiguration.LayoutMetrics.popoverHeight
        )
        .background(TactilePalette.obsidianBackground)
        .task {
            await registry.refreshAll()
            registry.availableUpdate = await releaseChecker.checkForUpdate()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.0))
                if !Task.isCancelled {
                    registry.refreshHardwareTelemetry()
                }
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("TACTILE TELEMETRY")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.tungstenAmber)

                Text(AppConfiguration.applicationName.uppercased())
                    .font(.system(size: 16, weight: .heavy, design: .default))
                    .tracking(1.1)
                    .foregroundStyle(TactilePalette.ivoryText)
            }

            // Compact inline search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundStyle(TactilePalette.slateDim)

                TextField("FILTER (SW.01, AUDIO, DARK)...", text: $registry.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(TactilePalette.ivoryText)

                if !registry.searchQuery.isEmpty {
                    Button {
                        registry.searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(TactilePalette.slateDim)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear filter query")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(TactilePalette.graphitePanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(TactilePalette.gridLine, lineWidth: 1)
                    )
            )

            HStack(spacing: 6) {
                Button {
                    registry.isShowingRadialDial.toggle()
                } label: {
                    Text(registry.isShowingRadialDial ? "DIAL: ON" : "DIAL: OFF")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    registry.isShowingRadialDial
                                        ? TactilePalette.tungstenAmber.opacity(0.18)
                                        : TactilePalette.graphitePanel
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(
                                            registry.isShowingRadialDial
                                                ? TactilePalette.tungstenAmber
                                                : TactilePalette.gridLine,
                                            lineWidth: 1
                                        )
                                )
                        )
                        .foregroundStyle(
                            registry.isShowingRadialDial
                                ? TactilePalette.tungstenAmber
                                : TactilePalette.silverMuted
                        )
                }
                .buttonStyle(.plain)
                .help("Show or hide the Concentric Telemetry Deck (Bluetooth RF, Rotary Dial & Storage Volumes)")

                Text(String(format: "SW %02d/%02d", registry.activeSwitchCount, registry.switches.count))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 7)
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
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TactilePalette.silverMuted)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(TactilePalette.graphitePanel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(TactilePalette.gridLine, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .keyboardShortcut("r", modifiers: .command)
                .accessibilityLabel("Refresh telemetry")
                .help("Synchronize telemetry across all 26 switches, storage volumes, and Bluetooth devices (⌘R)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 11)
        .padding(.bottom, 8)
    }

    private var domainFilterBar: some View {
        let pinCounts = registry.pinnedCounts
        return HStack(spacing: 5) {
            pinnedTabButton(countBadge: "\(pinCounts.active)/\(pinCounts.total)")

            ForEach(SwitchDomain.allCases, id: \.self) { domain in
                let counts = registry.domainCounts(for: domain)
                domainTabButton(
                    label: domain.shortCode,
                    countBadge: "\(counts.active)/\(counts.total)",
                    domain: domain,
                    accent: TactilePalette.accentColor(for: domain),
                    shortcutKey: shortcutKey(for: domain)
                )
            }

            Spacer(minLength: 2)

            domainTabButton(
                label: "ALL",
                countBadge: "\(registry.switches.count)",
                domain: nil,
                accent: TactilePalette.ivoryText,
                shortcutKey: "0"
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func pinnedTabButton(countBadge: String) -> some View {
        let isSelected = registry.isShowingPinnedOnly
        let accent = TactilePalette.tungstenAmber
        return Button {
            registry.selectPinnedFilter()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(isSelected ? accent : accent.opacity(0.75))

                Text("PIN")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSelected ? accent : TactilePalette.ivoryText)

                Text(countBadge)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isSelected ? accent.opacity(0.9) : TactilePalette.slateDim)
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? accent.opacity(0.18) : TactilePalette.graphitePanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isSelected ? accent : TactilePalette.gridLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .keyboardShortcut("p", modifiers: .command)
        .help("Pinned Daily Switches — 'Less, but better' (⌘P)")
    }

    private func shortcutKey(for domain: SwitchDomain) -> KeyEquivalent {
        switch domain {
        case .power:
            return "1"
        case .optics:
            return "2"
        case .workspace:
            return "3"
        case .signal:
            return "4"
        case .security:
            return "5"
        }
    }

    private func domainTabButton(
        label: String,
        countBadge: String,
        domain: SwitchDomain?,
        accent: Color,
        shortcutKey: KeyEquivalent
    ) -> some View {
        let isSelected = !registry.isShowingPinnedOnly && registry.selectedDomainFilter == domain
        return Button {
            registry.selectDomainFilter(domain)
        } label: {
            HStack(spacing: 5) {
                if domain != nil {
                    Circle()
                        .fill(isSelected ? accent : accent.opacity(0.65))
                        .frame(width: 5, height: 5)
                }

                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSelected ? accent : TactilePalette.ivoryText)

                Text(countBadge)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isSelected ? accent.opacity(0.9) : TactilePalette.slateDim)
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isSelected ? accent.opacity(0.18) : TactilePalette.graphitePanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(isSelected ? accent : TactilePalette.gridLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcutKey, modifiers: .command)
    }

    private var switchGridSection: some View {
        ScrollView {
            if registry.isShowingPinnedOnly && registry.filteredSwitches.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "pin.slash")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(TactilePalette.tungstenAmber)

                    Text("NO PINNED SWITCHES IN DECK")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.ivoryText)

                    Text("Select any domain tab (PWR–SEC or ALL) and click the pin icon on your daily switches, or restore the default 6-switch deck.")
                        .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(TactilePalette.silverMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)

                    Button {
                        registry.restoreDefaultPins()
                    } label: {
                        Text("RESTORE DEFAULT PINS (6)")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(TactilePalette.tungstenAmber.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(TactilePalette.tungstenAmber, lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(TactilePalette.tungstenAmber)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                LazyVGrid(columns: gridColumns, spacing: AppConfiguration.LayoutMetrics.gridSpacing) {
                    ForEach(registry.filteredSwitches, id: \.id) { item in
                        TactileSwitchCardView(
                            item: item,
                            isPinned: registry.isPinned(item.id),
                            onTrigger: {
                                Task {
                                    await registry.triggerSwitch(withID: item.id)
                                }
                            },
                            onTogglePin: {
                                registry.togglePin(forSwitchID: item.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .scrollIndicators(.automatic)
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

            ringToggleButton

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

    private var ringToggleButton: some View {
        let preferences = registry.ringPreferences
        let isOn = preferences.isEnabled
        return Button {
            preferences.isEnabled.toggle()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "circle.circle")
                    .font(.system(size: 9, weight: .bold))
                Text(isOn ? "RING \(RingPreferences.hotKeyLabel)" : "RING: OFF")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isOn ? TactilePalette.tungstenAmber.opacity(0.18) : TactilePalette.graphitePanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(isOn ? TactilePalette.tungstenAmber : TactilePalette.gridLine, lineWidth: 1)
                    )
            )
            .foregroundStyle(isOn ? TactilePalette.tungstenAmber : TactilePalette.silverMuted)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                registry.reorderRingByUsage()
            } label: {
                Label("Reorder Ring by Usage", systemImage: "arrow.up.arrow.down")
            }
        }
        .help(
            isOn
                ? "Radial Ring is on — hold \(RingPreferences.hotKeyLabel) anywhere to open your pinned switches. Right-click to reorder by usage."
                : "Turn on the Radial Ring: hold \(RingPreferences.hotKeyLabel) anywhere to fire your pinned switches at the cursor."
        )
    }
}
