import Foundation
import SwiftUI
import TactileCore

public struct DiskStorageTelemetry: Sendable {
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let mountedRemovableCount: Int

    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        let used = Double(totalBytes - freeBytes)
        return min(max(used / Double(totalBytes), 0.0), 1.0)
    }

    public var formattedFreeGB: String {
        let gb = Double(freeBytes) / 1_000_000_000.0
        return String(format: "%.0f GB FREE", gb)
    }

    public var formattedUsedRatio: String {
        let usedGB = Double(totalBytes - freeBytes) / 1_000_000_000.0
        let totalGB = Double(totalBytes) / 1_000_000_000.0
        return String(format: "%.0f / %.0f GB", usedGB, totalGB)
    }

    public static func current() -> DiskStorageTelemetry {
        let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/")
        let total = (attrs?[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free = (attrs?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0

        let keys: [URLResourceKey] = [.volumeIsRemovableKey, .volumeIsEjectableKey, .volumeIsInternalKey]
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        let removableCount = urls.filter { url in
            guard url.path != "/",
                  let vals = try? url.resourceValues(forKeys: Set(keys))
            else { return false }
            let isRemovable = vals.volumeIsRemovable ?? false
            let isEjectable = vals.volumeIsEjectable ?? false
            let isInternal = vals.volumeIsInternal ?? true
            return isRemovable || isEjectable || !isInternal
        }.count

        return DiskStorageTelemetry(
            totalBytes: total,
            freeBytes: free,
            mountedRemovableCount: removableCount
        )
    }
}

public struct TactileTelemetryDialView: View {
    @Bindable var registry: SwitchRegistry
    let storageTelemetry: DiskStorageTelemetry

    public init(registry: SwitchRegistry, storageTelemetry: DiskStorageTelemetry) {
        self.registry = registry
        self.storageTelemetry = storageTelemetry
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
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let maxR = min(size.width, size.height) / 2 - 4
                    let rOuter = maxR
                    let rSectorOuter = maxR * 0.84
                    let rSectorInner = maxR * 0.64
                    let rMid = maxR * 0.46
                    let rCore = maxR * 0.28

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
                    for r in [rSectorOuter, rSectorInner, rMid, rCore] {
                        let ringRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                        context.stroke(Path(ellipseIn: ringRect), with: .color(TactilePalette.gridLine), lineWidth: 0.85)
                    }

                    // 26 Radial Switch Nodes & Sector Arcs
                    let allSwitches = registry.switches
                    let total = max(allSwitches.count, 1)
                    let angleStep = (2.0 * Double.pi) / Double(total)
                    let baseOffset = -Double.pi / 2.0 // Start at 12 o'clock (000°)

                    for (index, item) in allSwitches.enumerated() {
                        let startAngle = baseOffset + Double(index) * angleStep
                        let endAngle = startAngle + angleStep * 0.78
                        let midAngle = startAngle + angleStep * 0.39
                        let accent = TactilePalette.accentColor(for: item.domain)
                        let isDomainSelected = registry.selectedDomainFilter == nil || registry.selectedDomainFilter == item.domain
                        let isOn = item.state.isEnabled

                        // Sector Band Segment
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

                        // Active Radial Telemetry Beam from Core to Sector
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

                        // Outer Perimeter Graduation Tick & LED Node
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
                .frame(width: 156, height: 156)

                // Center Readout Label
                VStack(spacing: 1) {
                    Text(String(format: "%02d/%02d", registry.activeSwitchCount, registry.switches.count))
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(TactilePalette.ivoryText)
                    Text("ONLINE")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.tungstenAmber)
                }
            }

            // Right Column: Disk & System Telemetry Readout
            VStack(alignment: .leading, spacing: 8) {
                Text("DISK & SYS TELEMETRY")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.slateDim)

                // Internal SSD Storage Gauge
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("SYS.VOL // SSD")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(TactilePalette.oscilloscopeCyan)
                        Spacer()
                        Text("\(Int(storageTelemetry.usedPercentage * 100))%")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(TactilePalette.ivoryText)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(TactilePalette.obsidianBackground)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(TactilePalette.oscilloscopeCyan)
                                .frame(width: geo.size.width * storageTelemetry.usedPercentage)
                        }
                    }
                    .frame(height: 5)

                    Text(storageTelemetry.formattedFreeGB)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(TactilePalette.ivoryText)

                    Text(storageTelemetry.formattedUsedRatio)
                        .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(TactilePalette.silverMuted)
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

                // Removable Disks & Total Triggers
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EXT.DISKS")
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(TactilePalette.slateDim)
                        Text(String(format: "%02d MOUNT", storageTelemetry.mountedRemovableCount))
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                storageTelemetry.mountedRemovableCount > 0
                                    ? TactilePalette.signalEmerald
                                    : TactilePalette.silverMuted
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(TactilePalette.obsidianBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                            )
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ACTUATIONS")
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(TactilePalette.slateDim)
                        Text(String(format: "%04d OPS", registry.totalTriggerCount))
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(TactilePalette.tungstenAmber)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
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
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(TactilePalette.graphitePanel.opacity(0.65))
    }
}
