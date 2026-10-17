import Foundation
import SwiftUI
import TactileCore

public struct TactileTelemetryDialView: View {
    @Bindable var registry: SwitchRegistry

    public init(registry: SwitchRegistry) {
        self.registry = registry
    }

    private var activeVolume: MountedVolumeInfo? {
        registry.selectedVolume
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Left Column: Domain Sector Legend (Interactive)
            VStack(alignment: .leading, spacing: 5) {
                Text("RADIAL SECTORS")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.slateDim)

                ForEach(SwitchDomain.allCases) { domain in
                    let isSelected = registry.selectedDomainFilter == domain
                    let domainSwitches = registry.switches.filter { $0.domain == domain }
                    let activeInDomain = domainSwitches.filter { $0.state.isEnabled }.count
                    let accent = TactilePalette.accentColor(for: domain)

                    Button {
                        registry.selectedDomainFilter = isSelected ? nil : domain
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accent)
                                .frame(width: 6, height: 6)

                            Text(domain.shortCode)
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? accent : TactilePalette.ivoryText)

                            Spacer(minLength: 4)

                            Text("\(activeInDomain)/\(domainSwitches.count)")
                                .font(.system(size: 9, weight: .regular, design: .monospaced))
                                .foregroundStyle(activeInDomain > 0 ? accent : TactilePalette.slateDim)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected ? accent.opacity(0.16) : TactilePalette.obsidianBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(isSelected ? accent : TactilePalette.gridLine, lineWidth: 0.8)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 112)

            // Centerpiece: Concentric Rotary Telemetry Disk (Visão do Disco)
            Button {
                registry.cycleNextVolume()
            } label: {
                ZStack {
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let maxR = min(size.width, size.height) / 2 - 4
                        let rOuter = maxR
                        let rSectorOuter = maxR * 0.84
                        let rSectorInner = maxR * 0.64
                        let rDiskArc = maxR * 0.49
                        let rCore = maxR * 0.35

                        // Background obsidian plate
                        let outerRect = CGRect(x: center.x - rOuter, y: center.y - rOuter, width: rOuter * 2, height: rOuter * 2)
                        context.fill(Path(ellipseIn: outerRect), with: .color(TactilePalette.obsidianBackground))
                        context.stroke(Path(ellipseIn: outerRect), with: .color(TactilePalette.borderSteel), lineWidth: 1.2)

                        // Crosshair Axes (000°, 090°, 180°, 270°)
                        var crosshair = Path()
                        crosshair.move(to: CGPoint(x: center.x - rOuter, y: center.y))
                        crosshair.addLine(to: CGPoint(x: center.x + rOuter, y: center.y))
                        crosshair.move(to: CGPoint(x: center.x, y: center.y - rOuter))
                        crosshair.addLine(to: CGPoint(x: center.x, y: center.y + rOuter))
                        context.stroke(crosshair, with: .color(TactilePalette.hairlineSubtle), lineWidth: 0.75)

                        // Concentric Reference Rings
                        for r in [rSectorOuter, rSectorInner, rDiskArc, rCore] {
                            let ringRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                            context.stroke(Path(ellipseIn: ringRect), with: .color(TactilePalette.gridLine), lineWidth: 0.85)
                        }

                        // Inner Disk Capacity Telemetry Ring (Selected Disk Usage Arc)
                        if let vol = activeVolume {
                            var diskTrack = Path()
                            diskTrack.addArc(
                                center: center,
                                radius: rDiskArc,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270),
                                clockwise: false
                            )
                            context.stroke(
                                diskTrack,
                                with: .color(TactilePalette.oscilloscopeCyan.opacity(0.15)),
                                style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                            )

                            let endDeg = -90.0 + (360.0 * vol.usedPercentage)
                            var diskFill = Path()
                            diskFill.addArc(
                                center: center,
                                radius: rDiskArc,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(endDeg),
                                clockwise: false
                            )
                            let diskColor = vol.usedPercentage > 0.88
                                ? TactilePalette.crimsonDanger
                                : (vol.isEjectable ? TactilePalette.signalEmerald : TactilePalette.oscilloscopeCyan)
                            context.stroke(
                                diskFill,
                                with: .color(diskColor),
                                style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                            )
                        }

                        // 26 Radial Switch Nodes & Sector Arcs
                        let allSwitches = registry.switches
                        let total = max(allSwitches.count, 1)
                        let angleStep = (2.0 * Double.pi) / Double(total)
                        let baseOffset = -Double.pi / 2.0

                        for (index, item) in allSwitches.enumerated() {
                            let startAngle = baseOffset + Double(index) * angleStep
                            let endAngle = startAngle + angleStep * 0.78
                            let midAngle = startAngle + angleStep * 0.39
                            let accent = TactilePalette.accentColor(for: item.domain)
                            let isDomainSelected = registry.selectedDomainFilter == nil || registry.selectedDomainFilter == item.domain
                            let isOn = item.state.isEnabled

                            var arcSegment = Path()
                            arcSegment.addArc(
                                center: center,
                                radius: (rSectorOuter + rSectorInner) / 2.0,
                                startAngle: .radians(startAngle),
                                endAngle: .radians(endAngle),
                                clockwise: false
                            )
                            context.stroke(
                                arcSegment,
                                with: .color(
                                    isOn
                                        ? accent
                                        : accent.opacity(isDomainSelected ? 0.35 : 0.12)
                                ),
                                style: StrokeStyle(lineWidth: rSectorOuter - rSectorInner - 3.0, lineCap: .butt)
                            )

                            if isOn {
                                var beam = Path()
                                beam.move(to: CGPoint(
                                    x: center.x + CGFloat(cos(midAngle)) * rCore,
                                    y: center.y + CGFloat(sin(midAngle)) * rCore
                                ))
                                beam.addLine(to: CGPoint(
                                    x: center.x + CGFloat(cos(midAngle)) * rSectorInner,
                                    y: center.y + CGFloat(sin(midAngle)) * rSectorInner
                                ))
                                context.stroke(beam, with: .color(accent.opacity(0.75)), lineWidth: 1.3)
                            }

                            let tickStart = rSectorOuter + 2.5
                            let tickEnd = rOuter - 3.5
                            var tick = Path()
                            tick.move(to: CGPoint(
                                x: center.x + CGFloat(cos(midAngle)) * tickStart,
                                y: center.y + CGFloat(sin(midAngle)) * tickStart
                            ))
                            tick.addLine(to: CGPoint(
                                x: center.x + CGFloat(cos(midAngle)) * tickEnd,
                                y: center.y + CGFloat(sin(midAngle)) * tickEnd
                            ))
                            context.stroke(
                                tick,
                                with: .color(isOn ? accent : TactilePalette.silverMuted.opacity(isDomainSelected ? 0.5 : 0.2)),
                                lineWidth: isOn ? 1.8 : 1.0
                            )

                            if isOn {
                                let ledCenter = CGPoint(
                                    x: center.x + CGFloat(cos(midAngle)) * (rOuter - 2.5),
                                    y: center.y + CGFloat(sin(midAngle)) * (rOuter - 2.5)
                                )
                                let ledRect = CGRect(x: ledCenter.x - 2.2, y: ledCenter.y - 2.2, width: 4.4, height: 4.4)
                                context.fill(Path(ellipseIn: ledRect), with: .color(accent))
                            }
                        }

                        // Center Core Hub
                        let coreRect = CGRect(x: center.x - rCore, y: center.y - rCore, width: rCore * 2, height: rCore * 2)
                        context.fill(Path(ellipseIn: coreRect), with: .color(TactilePalette.graphitePanel))
                        context.stroke(Path(ellipseIn: coreRect), with: .color(TactilePalette.tungstenAmber.opacity(0.7)), lineWidth: 1.2)
                    }
                    .frame(width: 158, height: 158)

                    // Compact Fixed-Code Center Readout (Never overflows the inner ring)
                    VStack(spacing: 1) {
                        if let vol = activeVolume {
                            Text(String(format: "%@.%02d", vol.kindBadge, registry.selectedVolumeIndex))
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(vol.isEjectable ? TactilePalette.signalEmerald : TactilePalette.oscilloscopeCyan)

                            Text("\(Int(vol.usedPercentage * 100))%")
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                .foregroundStyle(TactilePalette.ivoryText)

                            Text(String(format: "SW %02d/%02d", registry.activeSwitchCount, registry.switches.count))
                                .font(.system(size: 6.5, weight: .semibold, design: .monospaced))
                                .foregroundStyle(TactilePalette.tungstenAmber)
                        } else {
                            Text(String(format: "%02d/%02d", registry.activeSwitchCount, registry.switches.count))
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundStyle(TactilePalette.ivoryText)
                            Text("ONLINE")
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(TactilePalette.tungstenAmber)
                        }
                    }
                    .frame(width: 48)
                    .minimumScaleFactor(0.75)
                }
            }
            .buttonStyle(.plain)
            .help("Clique no centro do disco para alternar entre os volumes montados")

            // Right Column: Contained Stepper + Vertical Expandable Disk List
            VStack(alignment: .leading, spacing: 6) {
                // Top Stepper & Vertical List Selector Bar (Zero Horizontal Overflow)
                HStack(spacing: 4) {
                    Button {
                        registry.cyclePreviousVolume()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(TactilePalette.silverMuted)
                            .frame(width: 20, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(TactilePalette.obsidianBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                                    )
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Volume anterior")

                    Button {
                        registry.isShowingVolumeList.toggle()
                    } label: {
                        HStack(spacing: 5) {
                            Text(String(format: "%02d/%02d", registry.selectedVolumeIndex, registry.mountedVolumes.count))
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(TactilePalette.tungstenAmber)

                            Text(activeVolume?.name.uppercased() ?? "NO DISK")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(TactilePalette.ivoryText)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer(minLength: 2)

                            Image(systemName: registry.isShowingVolumeList ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(TactilePalette.tungstenAmber)
                        }
                        .padding(.horizontal, 7)
                        .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    registry.isShowingVolumeList
                                        ? TactilePalette.tungstenAmber.opacity(0.16)
                                        : TactilePalette.obsidianBackground
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(
                                            registry.isShowingVolumeList
                                                ? TactilePalette.tungstenAmber
                                                : TactilePalette.borderSteel,
                                            lineWidth: 0.9
                                        )
                                )
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Abrir lista vertical de todos os discos montados")

                    Button {
                        registry.cycleNextVolume()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(TactilePalette.silverMuted)
                            .frame(width: 20, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(TactilePalette.obsidianBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                                    )
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Próximo volume")
                }

                if registry.isShowingVolumeList {
                    // Vertical Scrollable Disk List (Handles unlimited disks without overflowing)
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 4) {
                            ForEach(Array(registry.mountedVolumes.enumerated()), id: \.element.id) { idx, volume in
                                let isSelected = volume.id == activeVolume?.id
                                let badgeColor = volume.isEjectable ? TactilePalette.signalEmerald : TactilePalette.oscilloscopeCyan

                                Button {
                                    registry.selectedVolumeID = volume.id
                                    registry.isShowingVolumeList = false
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(String(format: "%02d", idx + 1))
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundStyle(isSelected ? badgeColor : TactilePalette.slateDim)

                                        Text(volume.name.uppercased())
                                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                            .foregroundStyle(isSelected ? TactilePalette.ivoryText : TactilePalette.silverMuted)
                                            .lineLimit(1)
                                            .truncationMode(.middle)

                                        Spacer(minLength: 4)

                                        Text(volume.formattedFreeGB)
                                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                                            .foregroundStyle(badgeColor)
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(isSelected ? badgeColor.opacity(0.18) : TactilePalette.obsidianBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .strokeBorder(isSelected ? badgeColor : TactilePalette.gridLine, lineWidth: 0.8)
                                            )
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(height: 118)
                } else {
                    // Selected Disk Detailed Telemetry Card
                    if let vol = activeVolume {
                        let barColor = vol.usedPercentage > 0.88
                            ? TactilePalette.crimsonDanger
                            : (vol.isEjectable ? TactilePalette.signalEmerald : TactilePalette.oscilloscopeCyan)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("\(vol.kindBadge) // \(vol.name.uppercased())")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(barColor)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer(minLength: 4)
                                Text("\(Int(vol.usedPercentage * 100))%")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(TactilePalette.ivoryText)
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(TactilePalette.obsidianBackground)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(barColor)
                                        .frame(width: geo.size.width * vol.usedPercentage)
                                }
                            }
                            .frame(height: 5)

                            HStack {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(vol.formattedFreeGB)
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(TactilePalette.ivoryText)
                                    Text(vol.formattedUsedRatio)
                                        .font(.system(size: 8, weight: .regular, design: .monospaced))
                                        .foregroundStyle(TactilePalette.silverMuted)
                                }

                                Spacer()

                                Button {
                                    registry.revealSelectedVolumeInFinder()
                                } label: {
                                    Text("OPEN")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3.5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .strokeBorder(TactilePalette.borderSteel, lineWidth: 0.8)
                                        )
                                        .foregroundStyle(TactilePalette.ivoryText)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .help("Abrir este volume no Finder")

                                if vol.isEjectable {
                                    Button {
                                        registry.ejectSelectedVolume()
                                    } label: {
                                        Text("EJECT ⏏")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3.5)
                                            .background(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(TactilePalette.internationalOrange.opacity(0.22))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 3)
                                                            .strokeBorder(TactilePalette.internationalOrange, lineWidth: 0.8)
                                                    )
                                            )
                                            .foregroundStyle(TactilePalette.internationalOrange)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .help("Ejetar apenas o volume selecionado (\(vol.name))")
                                }
                            }
                        }
                        .padding(7)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(TactilePalette.obsidianBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                                )
                        )
                    }

                    // Bottom Row: Removable Disks Count & Total Actuations
                    HStack(spacing: 6) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("EXT.DISKS")
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(TactilePalette.slateDim)
                            Text(String(format: "%02d EJECTABLE", registry.ejectableVolumeCount))
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(
                                    registry.ejectableVolumeCount > 0
                                        ? TactilePalette.signalEmerald
                                        : TactilePalette.silverMuted
                                )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(TactilePalette.obsidianBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                                )
                        )

                        VStack(alignment: .leading, spacing: 1) {
                            Text("ACTUATIONS")
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(TactilePalette.slateDim)
                            Text(String(format: "%04d OPS", registry.totalTriggerCount))
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(TactilePalette.tungstenAmber)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(TactilePalette.obsidianBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                                )
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(TactilePalette.graphitePanel.opacity(0.65))
    }
}
