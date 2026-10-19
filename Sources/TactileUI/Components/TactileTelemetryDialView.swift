import Foundation
import SwiftUI
import TactileCore

public struct TactileTelemetryDialView: View {
    @Bindable var registry: SwitchRegistry

    public init(registry: SwitchRegistry) {
        self.registry = registry
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            BluetoothDeckColumnView(registry: registry)
                .frame(maxWidth: .infinity)

            ConcentricTelemetryDialCanvasView(registry: registry)

            StorageDeckColumnView(registry: registry)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(TactilePalette.graphitePanel.opacity(0.65))
    }
}

// MARK: - Lightweight Zero-GeometryReader Progress Bar

private struct TactileLinearBarView: View, Equatable {
    let ratio: Double
    let fillColor: Color
    let trackColor: Color
    let height: CGFloat

    init(
        ratio: Double,
        fillColor: Color,
        trackColor: Color = TactilePalette.graphitePanel,
        height: CGFloat = 4.0
    ) {
        self.ratio = min(max(ratio, 0.02), 1.0)
        self.fillColor = fillColor
        self.trackColor = trackColor
        self.height = height
    }

    var body: some View {
        Canvas { context, size in
            let corner = size.height / 2.0
            let fullRect = CGRect(origin: .zero, size: size)
            context.fill(
                Path(roundedRect: fullRect, cornerRadius: corner),
                with: .color(trackColor)
            )

            let fillWidth = max(size.height, size.width * ratio)
            let fillRect = CGRect(x: 0, y: 0, width: min(fillWidth, size.width), height: size.height)
            context.fill(
                Path(roundedRect: fillRect, cornerRadius: corner),
                with: .color(fillColor)
            )
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Left Deck: Bluetooth RF Selector + CPU/RAM Telemetry

private struct BluetoothDeckColumnView: View {
    @Bindable var registry: SwitchRegistry

    private var activeBluetooth: BluetoothDeviceItem? {
        registry.selectedBluetoothDevice
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            stepperBar

            if registry.isShowingBluetoothList {
                deviceDropdownList
            } else {
                activeDeviceCard
                cpuAndMemoryGauges
            }
        }
    }

    private var stepperBar: some View {
        HStack(spacing: 4) {
            Button(action: registry.cyclePreviousBluetoothDevice) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(TactilePalette.silverMuted)
                    .frame(width: 18, height: 21)
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
            .accessibilityLabel("Previous paired Bluetooth device")
            .help("Previous paired Bluetooth device")

            Button {
                registry.isShowingBluetoothList.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(String(format: "%02d/%02d", registry.selectedBluetoothIndex, registry.pairedBluetoothDevices.count))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.signalEmerald)

                    Text(activeBluetooth?.name.uppercased() ?? "NO BT DEVICE")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.ivoryText)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 2)

                    Image(systemName: registry.isShowingBluetoothList ? "chevron.up" : "chevron.down")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(TactilePalette.signalEmerald)
                }
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 21, maxHeight: 21)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            registry.isShowingBluetoothList
                                ? TactilePalette.signalEmerald.opacity(0.16)
                                : TactilePalette.obsidianBackground
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(
                                    registry.isShowingBluetoothList
                                        ? TactilePalette.signalEmerald
                                        : TactilePalette.borderSteel,
                                    lineWidth: 0.9
                                )
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select Bluetooth device")
            .accessibilityValue(activeBluetooth?.name ?? "None")
            .help("Expand vertical list of paired Bluetooth devices")

            Button(action: registry.cycleNextBluetoothDevice) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(TactilePalette.silverMuted)
                    .frame(width: 18, height: 21)
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
            .accessibilityLabel("Next paired Bluetooth device")
            .help("Next paired Bluetooth device")
        }
    }

    private var deviceDropdownList: some View {
        ScrollView(.vertical) {
            VStack(spacing: 4) {
                ForEach(registry.pairedBluetoothDevices) { device in
                    let isSelected = device.id == activeBluetooth?.id
                    let accent = device.isConnected ? TactilePalette.signalEmerald : TactilePalette.tungstenAmber

                    Button {
                        registry.selectedBluetoothDeviceID = device.id
                        registry.isShowingBluetoothList = false
                        Task {
                            if let btSwitch = registry.switches.first(where: { $0.id == "SW.17" }) {
                                await btSwitch.refreshState()
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(device.isConnected ? TactilePalette.signalEmerald : TactilePalette.slateDim)
                                .frame(width: 5, height: 5)

                            Text(device.name.uppercased())
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? TactilePalette.ivoryText : TactilePalette.silverMuted)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer(minLength: 2)

                            Text(device.isConnected ? "ON" : "OFF")
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(device.isConnected ? TactilePalette.signalEmerald : TactilePalette.slateDim)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4.5)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected ? accent.opacity(0.18) : TactilePalette.obsidianBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(isSelected ? accent : TactilePalette.gridLine, lineWidth: 0.8)
                                )
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.automatic)
        .frame(height: 112)
    }

    @ViewBuilder
    private var activeDeviceCard: some View {
        if let bt = activeBluetooth {
            let isBusy = registry.connectingBluetoothDeviceID == bt.id
            let statusColor = isBusy
                ? TactilePalette.tungstenAmber
                : (bt.isConnected ? TactilePalette.signalEmerald : TactilePalette.silverMuted)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(bt.kindBadge) // \(bt.name.uppercased())")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(bt.isConnected ? TactilePalette.signalEmerald : TactilePalette.tungstenAmber)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 2)
                    Circle()
                        .fill(bt.isConnected ? TactilePalette.signalEmerald : TactilePalette.slateDim)
                        .frame(width: 6, height: 6)
                }

                TactileLinearBarView(
                    ratio: bt.isConnected ? 1.0 : 0.22,
                    fillColor: bt.isConnected ? TactilePalette.signalEmerald : TactilePalette.slateDim.opacity(0.35),
                    trackColor: TactilePalette.obsidianBackground,
                    height: 5.0
                )

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(isBusy ? "LINKING RF..." : (bt.isConnected ? "RF CONNECTED" : "STANDBY"))
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(statusColor)
                        Text(bt.address)
                            .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                            .foregroundStyle(TactilePalette.slateDim)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 2)

                    Button {
                        Task {
                            await registry.toggleSelectedBluetoothDevice()
                        }
                    } label: {
                        Text(bt.isConnected ? "DISCONNECT" : "CONNECT")
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3.5)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        bt.isConnected
                                            ? TactilePalette.internationalOrange.opacity(0.22)
                                            : TactilePalette.signalEmerald.opacity(0.22)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .strokeBorder(
                                                bt.isConnected ? TactilePalette.internationalOrange : TactilePalette.signalEmerald,
                                                lineWidth: 0.8
                                            )
                                    )
                            )
                            .foregroundStyle(bt.isConnected ? TactilePalette.internationalOrange : TactilePalette.signalEmerald)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(bt.isConnected ? "Disconnect \(bt.name)" : "Connect \(bt.name)")
                }
            }
            .padding(6.5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(TactilePalette.obsidianBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                    )
            )
        }
    }

    private var cpuAndMemoryGauges: some View {
        let hw = registry.hardwareTelemetry
        return HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 2.5) {
                HStack {
                    Text("CPU.LOAD")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.slateDim)
                    Spacer(minLength: 2)
                    Text("\(hw.cpuTotalPercent)%")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.tungstenAmber)
                }

                Text("USR \(hw.cpuUserPercent) · SYS \(hw.cpuSystemPercent)%")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.ivoryText)
                    .lineLimit(1)

                TactileLinearBarView(
                    ratio: hw.cpuTotalRatio,
                    fillColor: TactilePalette.tungstenAmber,
                    height: 3.5
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4.5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(TactilePalette.obsidianBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(TactilePalette.tungstenAmber.opacity(0.45), lineWidth: 0.8)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("CPU Load")
            .accessibilityValue("\(hw.cpuTotalPercent) percent")

            VStack(alignment: .leading, spacing: 2.5) {
                HStack {
                    Text("MEM.RAM")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.slateDim)
                    Spacer(minLength: 2)
                    Text("\(hw.memoryUsedPercent)%")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.signalEmerald)
                }

                Text(hw.memoryFormattedRatio)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.ivoryText)
                    .lineLimit(1)

                TactileLinearBarView(
                    ratio: hw.memoryUsedRatio,
                    fillColor: TactilePalette.signalEmerald,
                    height: 3.5
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4.5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(TactilePalette.obsidianBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(TactilePalette.signalEmerald.opacity(0.45), lineWidth: 0.8)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Memory Pressure")
            .accessibilityValue("\(hw.memoryUsedPercent) percent, \(hw.memoryFormattedRatio)")
        }
    }
}

// MARK: - Centerpiece: Triple Concentric Rotary Telemetry Disk

private struct ConcentricTelemetryDialCanvasView: View {
    @Bindable var registry: SwitchRegistry

    private var activeVolume: MountedVolumeInfo? {
        registry.selectedVolume
    }

    var body: some View {
        let hw = registry.hardwareTelemetry
        Button(action: registry.cycleNextVolume) {
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let maxR = min(size.width, size.height) / 2 - 3
                    let rOuter = maxR
                    let rSectorOuter = maxR * 0.86
                    let rSectorInner = maxR * 0.74
                    let rCpuArc = maxR * 0.65
                    let rRamArc = maxR * 0.54
                    let rDiskArc = maxR * 0.43
                    let rCore = maxR * 0.33

                    let outerRect = CGRect(x: center.x - rOuter, y: center.y - rOuter, width: rOuter * 2, height: rOuter * 2)
                    context.fill(Path(ellipseIn: outerRect), with: .color(TactilePalette.obsidianBackground))
                    context.stroke(Path(ellipseIn: outerRect), with: .color(TactilePalette.borderSteel), lineWidth: 1.2)

                    var crosshair = Path()
                    crosshair.move(to: CGPoint(x: center.x - rOuter, y: center.y))
                    crosshair.addLine(to: CGPoint(x: center.x + rOuter, y: center.y))
                    crosshair.move(to: CGPoint(x: center.x, y: center.y - rOuter))
                    crosshair.addLine(to: CGPoint(x: center.x, y: center.y + rOuter))
                    context.stroke(crosshair, with: .color(TactilePalette.hairlineSubtle), lineWidth: 0.75)

                    for r in [rSectorOuter, rSectorInner, rCore] {
                        let ringRect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                        context.stroke(Path(ellipseIn: ringRect), with: .color(TactilePalette.gridLine), lineWidth: 0.85)
                    }

                    // Ring 1: CPU Load Arc (Amber)
                    var cpuTrack = Path()
                    cpuTrack.addArc(center: center, radius: rCpuArc, startAngle: .degrees(-90), endAngle: .degrees(270), clockwise: false)
                    context.stroke(cpuTrack, with: .color(TactilePalette.tungstenAmber.opacity(0.15)), style: StrokeStyle(lineWidth: 4.2, lineCap: .round))

                    var cpuFill = Path()
                    cpuFill.addArc(
                        center: center,
                        radius: rCpuArc,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90.0 + 360.0 * hw.cpuTotalRatio),
                        clockwise: false
                    )
                    context.stroke(cpuFill, with: .color(TactilePalette.tungstenAmber), style: StrokeStyle(lineWidth: 4.2, lineCap: .round))

                    // Ring 2: Memory RAM Saturation Arc (Emerald)
                    var ramTrack = Path()
                    ramTrack.addArc(center: center, radius: rRamArc, startAngle: .degrees(-90), endAngle: .degrees(270), clockwise: false)
                    context.stroke(ramTrack, with: .color(TactilePalette.signalEmerald.opacity(0.15)), style: StrokeStyle(lineWidth: 4.2, lineCap: .round))

                    var ramFill = Path()
                    ramFill.addArc(
                        center: center,
                        radius: rRamArc,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90.0 + 360.0 * hw.memoryUsedRatio),
                        clockwise: false
                    )
                    context.stroke(ramFill, with: .color(TactilePalette.signalEmerald), style: StrokeStyle(lineWidth: 4.2, lineCap: .round))

                    // Ring 3: Storage Disk Saturation Arc (Cyan)
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
                            style: StrokeStyle(lineWidth: 4.2, lineCap: .round)
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
                            style: StrokeStyle(lineWidth: 4.2, lineCap: .round)
                        )
                    }

                    let allSwitches = registry.switches
                    let total = max(allSwitches.count, 1)
                    let angleStep = (2.0 * Double.pi) / Double(total)
                    let baseOffset = -Double.pi / 2.0

                    for (index, item) in allSwitches.enumerated() {
                        let startAngle = baseOffset + Double(index) * angleStep
                        let endAngle = startAngle + angleStep * 0.78
                        let midAngle = startAngle + angleStep * 0.39
                        let accent = TactilePalette.accentColor(for: item.domain)
                        let isDomainSelected = registry.isShowingPinnedOnly
                            ? registry.isPinned(item.id)
                            : (registry.selectedDomainFilter == nil || registry.selectedDomainFilter == item.domain)
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
                            style: StrokeStyle(lineWidth: rSectorOuter - rSectorInner - 2.2, lineCap: .butt)
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
                            context.stroke(beam, with: .color(accent.opacity(0.65)), lineWidth: 1.1)
                        }

                        let tickStart = rSectorOuter + 2.0
                        let tickEnd = rOuter - 3.0
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
                            lineWidth: isOn ? 1.6 : 0.9
                        )

                        if isOn {
                            let ledCenter = CGPoint(
                                x: center.x + CGFloat(cos(midAngle)) * (rOuter - 2.2),
                                y: center.y + CGFloat(sin(midAngle)) * (rOuter - 2.2)
                            )
                            let ledRect = CGRect(x: ledCenter.x - 2.0, y: ledCenter.y - 2.0, width: 4.0, height: 4.0)
                            context.fill(Path(ellipseIn: ledRect), with: .color(accent))
                        }
                    }

                    let coreRect = CGRect(x: center.x - rCore, y: center.y - rCore, width: rCore * 2, height: rCore * 2)
                    context.fill(Path(ellipseIn: coreRect), with: .color(TactilePalette.graphitePanel))
                    context.stroke(Path(ellipseIn: coreRect), with: .color(TactilePalette.tungstenAmber.opacity(0.75)), lineWidth: 1.2)
                }
                .frame(width: 142, height: 142)

                VStack(spacing: 1) {
                    Text("C:\(hw.cpuTotalPercent) R:\(hw.memoryUsedPercent)")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.signalEmerald)

                    if let vol = activeVolume {
                        Text(vol.usedPercentage, format: .percent.precision(.fractionLength(0)))
                            .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(TactilePalette.ivoryText)

                        Text(String(format: "%@.%02d", vol.kindBadge, registry.selectedVolumeIndex))
                            .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(vol.isEjectable ? TactilePalette.signalEmerald : TactilePalette.oscilloscopeCyan)
                    } else {
                        Text(String(format: "%02d/%02d", registry.activeSwitchCount, registry.switches.count))
                            .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(TactilePalette.ivoryText)
                        Text("ONLINE")
                            .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(TactilePalette.tungstenAmber)
                    }
                }
                .frame(width: 44)
                .minimumScaleFactor(0.75)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Concentric Hardware Telemetry Dial")
        .accessibilityValue("CPU \(hw.cpuTotalPercent)%, RAM \(hw.memoryUsedPercent)%, Volume \(activeVolume?.name ?? "None")")
        .accessibilityAddTraits(.isButton)
        .help("Concentric Telemetry Rings — Outer: 26 Switches | Amber: CPU Load | Emerald: RAM Usage | Cyan: Disk Saturation. Click core to cycle storage volumes.")
    }
}

// MARK: - Right Deck: Storage Volumes Selector + Power/Thermal Telemetry

private struct StorageDeckColumnView: View {
    @Bindable var registry: SwitchRegistry

    private var activeVolume: MountedVolumeInfo? {
        registry.selectedVolume
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            stepperBar

            if registry.isShowingVolumeList {
                volumeDropdownList
            } else {
                activeVolumeCard
                powerAndThermalGauges
            }
        }
    }

    private var stepperBar: some View {
        HStack(spacing: 4) {
            Button(action: registry.cyclePreviousVolume) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(TactilePalette.silverMuted)
                    .frame(width: 18, height: 21)
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
            .accessibilityLabel("Previous storage volume")
            .help("Previous storage volume")

            Button {
                registry.isShowingVolumeList.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(String(format: "%02d/%02d", registry.selectedVolumeIndex, registry.mountedVolumes.count))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.oscilloscopeCyan)

                    Text(activeVolume?.name.uppercased() ?? "NO DISK")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.ivoryText)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 2)

                    Image(systemName: registry.isShowingVolumeList ? "chevron.up" : "chevron.down")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(TactilePalette.oscilloscopeCyan)
                }
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 21, maxHeight: 21)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            registry.isShowingVolumeList
                                ? TactilePalette.oscilloscopeCyan.opacity(0.16)
                                : TactilePalette.obsidianBackground
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(
                                    registry.isShowingVolumeList
                                        ? TactilePalette.oscilloscopeCyan
                                        : TactilePalette.borderSteel,
                                    lineWidth: 0.9
                                )
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select storage volume")
            .accessibilityValue(activeVolume?.name ?? "None")
            .help("Expand vertical list of mounted storage volumes")

            Button(action: registry.cycleNextVolume) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundStyle(TactilePalette.silverMuted)
                    .frame(width: 18, height: 21)
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
            .accessibilityLabel("Next storage volume")
            .help("Next storage volume")
        }
    }

    private var volumeDropdownList: some View {
        ScrollView(.vertical) {
            VStack(spacing: 4) {
                ForEach(registry.mountedVolumes) { volume in
                    let isSelected = volume.id == activeVolume?.id
                    let badgeColor = volume.isEjectable ? TactilePalette.signalEmerald : TactilePalette.oscilloscopeCyan

                    Button {
                        registry.selectedVolumeID = volume.id
                        registry.isShowingVolumeList = false
                    } label: {
                        HStack(spacing: 5) {
                            Text(volume.kindBadge)
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? badgeColor : TactilePalette.slateDim)

                            Text(volume.name.uppercased())
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? TactilePalette.ivoryText : TactilePalette.silverMuted)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer(minLength: 2)

                            Text(volume.formattedFreeGB)
                                .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                                .foregroundStyle(badgeColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4.5)
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
        .scrollIndicators(.automatic)
        .frame(height: 112)
    }

    @ViewBuilder
    private var activeVolumeCard: some View {
        if let vol = activeVolume {
            let barColor = vol.usedPercentage > 0.88
                ? TactilePalette.crimsonDanger
                : (vol.isEjectable ? TactilePalette.signalEmerald : TactilePalette.oscilloscopeCyan)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("\(vol.kindBadge) // \(vol.name.uppercased())")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(barColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 2)
                    Text(vol.usedPercentage, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.ivoryText)
                }

                TactileLinearBarView(
                    ratio: vol.usedPercentage,
                    fillColor: barColor,
                    trackColor: TactilePalette.obsidianBackground,
                    height: 5.0
                )

                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(vol.formattedFreeGB)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(TactilePalette.ivoryText)
                        Text(vol.formattedUsedRatio)
                            .font(.system(size: 7.5, weight: .regular, design: .monospaced))
                            .foregroundStyle(TactilePalette.silverMuted)
                    }

                    Spacer(minLength: 2)

                    Button(action: registry.revealSelectedVolumeInFinder) {
                        Text("OPEN")
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 3.5)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(TactilePalette.borderSteel, lineWidth: 0.8)
                            )
                            .foregroundStyle(TactilePalette.ivoryText)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Reveal volume in Finder")

                    if vol.isEjectable {
                        Button(action: registry.ejectSelectedVolume) {
                            Text("EJECT ⏏")
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 5.5)
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
                        .help("Safely eject selected volume (\(vol.name))")
                    }
                }
            }
            .padding(6.5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(TactilePalette.obsidianBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                    )
            )
        }
    }

    private var powerAndThermalGauges: some View {
        let hw = registry.hardwareTelemetry
        return HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 2.5) {
                HStack {
                    Text("PWR.SOURCE")
                        .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.slateDim)
                    Spacer(minLength: 2)
                    Text(hw.powerPercentLabel)
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(TactilePalette.oscilloscopeCyan)
                }

                Text(hw.powerSourceLabel)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.ivoryText)
                    .lineLimit(1)

                TactileLinearBarView(
                    ratio: hw.powerLevelRatio,
                    fillColor: TactilePalette.oscilloscopeCyan,
                    height: 3.5
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4.5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(TactilePalette.obsidianBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(TactilePalette.oscilloscopeCyan.opacity(0.45), lineWidth: 0.8)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Power Source")
            .accessibilityValue("\(hw.powerPercentLabel), \(hw.powerSourceLabel)")

            VStack(alignment: .leading, spacing: 2) {
                Text("THERMAL")
                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.slateDim)

                Text(hw.thermalStateLabel)
                    .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(
                        hw.isThermalElevated
                            ? TactilePalette.internationalOrange
                            : TactilePalette.signalEmerald
                    )

                Text(String(format: "%04d OPS", registry.totalTriggerCount))
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(TactilePalette.tungstenAmber)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4.5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(TactilePalette.obsidianBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(TactilePalette.gridLine, lineWidth: 0.8)
                    )
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Thermal State and Actuations")
            .accessibilityValue("\(hw.thermalStateLabel), \(registry.totalTriggerCount) operations")
        }
    }
}
