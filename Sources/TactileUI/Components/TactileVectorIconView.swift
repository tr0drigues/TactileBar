import SwiftUI
import TactileCore

public struct TactileVectorIconView: View {
    let switchID: String
    let isActive: Bool
    let accentColor: Color

    public init(switchID: String, isActive: Bool, accentColor: Color) {
        self.switchID = switchID
        self.isActive = isActive
        self.accentColor = accentColor
    }

    public var body: some View {
        ZStack {
            // Outer Horological Bezel with 12 Graduated Ticks
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let outerRadius = min(size.width, size.height) / 2 - 1.5
                let innerRadius = outerRadius - 4.0

                // Base obsidian well
                let wellRect = CGRect(
                    x: center.x - outerRadius,
                    y: center.y - outerRadius,
                    width: outerRadius * 2,
                    height: outerRadius * 2
                )
                context.fill(Path(ellipseIn: wellRect), with: .color(TactilePalette.obsidianBackground))

                // Subtle radial glow when active
                if isActive {
                    let glowRect = wellRect.insetBy(dx: 3, dy: 3)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(accentColor.opacity(0.14))
                    )
                }

                // Outer bezel ring
                context.stroke(
                    Path(ellipseIn: wellRect),
                    with: .color(isActive ? accentColor.opacity(0.9) : TactilePalette.borderSteel),
                    lineWidth: isActive ? 1.5 : 1.0
                )

                // 12 Horological Graduation Ticks
                for tick in 0..<12 {
                    let angle = Double(tick) * (.pi / 6.0)
                    let isCardinal = tick % 3 == 0
                    let rStart = isCardinal ? (outerRadius - 4.5) : (outerRadius - 3.0)
                    let rEnd = outerRadius - 1.2
                    let p1 = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * rStart,
                        y: center.y + CGFloat(sin(angle)) * rStart
                    )
                    let p2 = CGPoint(
                        x: center.x + CGFloat(cos(angle)) * rEnd,
                        y: center.y + CGFloat(sin(angle)) * rEnd
                    )
                    var tickPath = Path()
                    tickPath.move(to: p1)
                    tickPath.addLine(to: p2)
                    context.stroke(
                        tickPath,
                        with: .color(
                            isActive
                                ? (isCardinal ? accentColor : accentColor.opacity(0.45))
                                : (isCardinal ? TactilePalette.silverMuted.opacity(0.55) : TactilePalette.gridLine)
                        ),
                        lineWidth: isCardinal ? 1.2 : 0.8
                    )
                }

                // Inner precision ring
                let innerRect = CGRect(
                    x: center.x - innerRadius,
                    y: center.y - innerRadius,
                    width: innerRadius * 2,
                    height: innerRadius * 2
                )
                context.stroke(
                    Path(ellipseIn: innerRect),
                    with: .color(isActive ? accentColor.opacity(0.28) : TactilePalette.hairlineSubtle),
                    lineWidth: 0.75
                )

                // Bespoke Vector Schematic per Switch ID
                drawSchematic(in: &context, center: center, scale: outerRadius * 0.56)
            }
            .frame(width: 52, height: 52)
        }
    }

    private var primaryStroke: GraphicsContext.Shading {
        .color(isActive ? accentColor : TactilePalette.ivoryText)
    }

    private var secondaryStroke: GraphicsContext.Shading {
        .color(isActive ? TactilePalette.ivoryText.opacity(0.9) : TactilePalette.silverMuted)
    }

    private var accentFill: GraphicsContext.Shading {
        .color(isActive ? accentColor.opacity(0.28) : TactilePalette.silverMuted.opacity(0.12))
    }

    private func drawSchematic(in context: inout GraphicsContext, center: CGPoint, scale r: CGFloat) {
        let strokeStyle = StrokeStyle(lineWidth: 1.65, lineCap: .round, lineJoin: .round)
        let thinStyle = StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round)

        switch switchID {
        case "SW.01": // KEEP AWAKE: Espresso Cup + 3 Steam Waves
            let cupRect = CGRect(x: center.x - r * 0.62, y: center.y - r * 0.15, width: r * 1.05, height: r * 0.72)
            let cupPath = Path(roundedRect: cupRect, cornerSize: CGSize(width: 3, height: 5))
            context.fill(cupPath, with: accentFill)
            context.stroke(cupPath, with: primaryStroke, style: strokeStyle)

            var handle = Path()
            handle.addArc(
                center: CGPoint(x: cupRect.maxX, y: cupRect.midY),
                radius: r * 0.22,
                startAngle: .degrees(-70),
                endAngle: .degrees(70),
                clockwise: false
            )
            context.stroke(handle, with: primaryStroke, style: strokeStyle)

            var saucer = Path()
            saucer.move(to: CGPoint(x: center.x - r * 0.8, y: cupRect.maxY + r * 0.16))
            saucer.addLine(to: CGPoint(x: center.x + r * 0.7, y: cupRect.maxY + r * 0.16))
            context.stroke(saucer, with: secondaryStroke, style: strokeStyle)

            for offset in [-0.35, -0.08, 0.20] {
                let x = center.x + r * CGFloat(offset)
                var steam = Path()
                steam.move(to: CGPoint(x: x, y: cupRect.minY - r * 0.12))
                steam.addCurve(
                    to: CGPoint(x: x + r * 0.06, y: cupRect.minY - r * 0.55),
                    control1: CGPoint(x: x - r * 0.12, y: cupRect.minY - r * 0.28),
                    control2: CGPoint(x: x + r * 0.18, y: cupRect.minY - r * 0.40)
                )
                context.stroke(steam, with: secondaryStroke, style: thinStyle)
            }

        case "SW.02": // DISPLAY SLEEP: Monitor + Standby Crescent
            drawMonitorFrame(in: &context, center: center, r: r, strokeStyle: strokeStyle)
            var moon = Path()
            moon.addArc(
                center: CGPoint(x: center.x, y: center.y - r * 0.14),
                radius: r * 0.24,
                startAngle: .degrees(35),
                endAngle: .degrees(245),
                clockwise: false
            )
            context.stroke(moon, with: secondaryStroke, style: thinStyle)

        case "SW.03": // SCREEN SAVER: Monitor + Orbital Sparkles
            drawMonitorFrame(in: &context, center: center, r: r, strokeStyle: strokeStyle)
            drawFourPointStar(in: &context, center: CGPoint(x: center.x - r * 0.15, y: center.y - r * 0.15), radius: r * 0.24)
            drawFourPointStar(in: &context, center: CGPoint(x: center.x + r * 0.25, y: center.y - r * 0.25), radius: r * 0.13)

        case "SW.04": // LOW POWER MODE: Precision Battery + Eco Bolt
            let bodyRect = CGRect(x: center.x - r * 0.78, y: center.y - r * 0.42, width: r * 1.40, height: r * 0.84)
            let bodyPath = Path(roundedRect: bodyRect, cornerRadius: 3)
            context.stroke(bodyPath, with: primaryStroke, style: strokeStyle)

            let capRect = CGRect(x: bodyRect.maxX + 1.5, y: center.y - r * 0.20, width: r * 0.14, height: r * 0.40)
            context.fill(Path(roundedRect: capRect, cornerRadius: 1), with: primaryStroke)

            let fillRect = bodyRect.insetBy(dx: 3.0, dy: 3.0)
            let halfFill = CGRect(x: fillRect.minX, y: fillRect.minY, width: fillRect.width * 0.48, height: fillRect.height)
            context.fill(Path(roundedRect: halfFill, cornerRadius: 1.5), with: primaryStroke)

        case "SW.05": // HIGH POWER MODE: Tachometer Gauge + Needle
            var arc = Path()
            arc.addArc(
                center: CGPoint(x: center.x, y: center.y + r * 0.18),
                radius: r * 0.78,
                startAngle: .degrees(195),
                endAngle: .degrees(345),
                clockwise: false
            )
            context.stroke(arc, with: primaryStroke, style: strokeStyle)

            var needle = Path()
            let pivot = CGPoint(x: center.x, y: center.y + r * 0.18)
            needle.move(to: pivot)
            needle.addLine(to: CGPoint(x: center.x + r * 0.48, y: center.y - r * 0.36))
            context.stroke(needle, with: secondaryStroke, style: strokeStyle)
            context.fill(
                Path(ellipseIn: CGRect(x: pivot.x - 2.5, y: pivot.y - 2.5, width: 5, height: 5)),
                with: primaryStroke
            )

        case "SW.06": // DARK MODE: Split Eclipse Sun/Moon Dial
            let circleRect = CGRect(x: center.x - r * 0.68, y: center.y - r * 0.68, width: r * 1.36, height: r * 1.36)
            context.stroke(Path(ellipseIn: circleRect), with: primaryStroke, style: strokeStyle)
            var leftHalf = Path()
            leftHalf.addArc(
                center: center,
                radius: r * 0.68,
                startAngle: .degrees(90),
                endAngle: .degrees(270),
                clockwise: false
            )
            leftHalf.closeSubpath()
            context.fill(leftHalf, with: primaryStroke)

        case "SW.07": // NIGHT SHIFT: Horizon Sun + Warm Rays
            var horizon = Path()
            horizon.move(to: CGPoint(x: center.x - r * 0.82, y: center.y + r * 0.20))
            horizon.addLine(to: CGPoint(x: center.x + r * 0.82, y: center.y + r * 0.20))
            context.stroke(horizon, with: primaryStroke, style: strokeStyle)

            var sunArc = Path()
            sunArc.addArc(
                center: CGPoint(x: center.x, y: center.y + r * 0.20),
                radius: r * 0.44,
                startAngle: .degrees(180),
                endAngle: .degrees(360),
                clockwise: false
            )
            context.fill(sunArc, with: accentFill)
            context.stroke(sunArc, with: primaryStroke, style: strokeStyle)

            for deg in stride(from: 200.0, through: 340.0, by: 35.0) {
                let rad = deg * .pi / 180.0
                let baseCenter = CGPoint(x: center.x, y: center.y + r * 0.20)
                var ray = Path()
                ray.move(to: CGPoint(x: baseCenter.x + CGFloat(cos(rad)) * r * 0.56, y: baseCenter.y + CGFloat(sin(rad)) * r * 0.56))
                ray.addLine(to: CGPoint(x: baseCenter.x + CGFloat(cos(rad)) * r * 0.76, y: baseCenter.y + CGFloat(sin(rad)) * r * 0.76))
                context.stroke(ray, with: secondaryStroke, style: thinStyle)
            }

        case "SW.08": // TRUE TONE: Dual Intersecting Chromatic Rings
            let leftRect = CGRect(x: center.x - r * 0.72, y: center.y - r * 0.48, width: r * 0.96, height: r * 0.96)
            let rightRect = CGRect(x: center.x - r * 0.24, y: center.y - r * 0.48, width: r * 0.96, height: r * 0.96)
            context.fill(Path(ellipseIn: leftRect), with: accentFill)
            context.stroke(Path(ellipseIn: leftRect), with: primaryStroke, style: strokeStyle)
            context.stroke(Path(ellipseIn: rightRect), with: secondaryStroke, style: strokeStyle)

        case "SW.09": // DISPLAY RESOLUTION: 4-Corner Reticle + Diagonal Vector
            let b = r * 0.68
            let seg = r * 0.30
            var corners = Path()
            // Top-Left
            corners.move(to: CGPoint(x: center.x - b, y: center.y - b + seg))
            corners.addLine(to: CGPoint(x: center.x - b, y: center.y - b))
            corners.addLine(to: CGPoint(x: center.x - b + seg, y: center.y - b))
            // Top-Right
            corners.move(to: CGPoint(x: center.x + b - seg, y: center.y - b))
            corners.addLine(to: CGPoint(x: center.x + b, y: center.y - b))
            corners.addLine(to: CGPoint(x: center.x + b, y: center.y - b + seg))
            // Bottom-Left
            corners.move(to: CGPoint(x: center.x - b, y: center.y + b - seg))
            corners.addLine(to: CGPoint(x: center.x - b, y: center.y + b))
            corners.addLine(to: CGPoint(x: center.x - b + seg, y: center.y + b))
            // Bottom-Right
            corners.move(to: CGPoint(x: center.x + b - seg, y: center.y + b))
            corners.addLine(to: CGPoint(x: center.x + b, y: center.y + b))
            corners.addLine(to: CGPoint(x: center.x + b, y: center.y + b - seg))
            context.stroke(corners, with: primaryStroke, style: strokeStyle)

            var diag = Path()
            diag.move(to: CGPoint(x: center.x - r * 0.35, y: center.y + r * 0.35))
            diag.addLine(to: CGPoint(x: center.x + r * 0.35, y: center.y - r * 0.35))
            context.stroke(diag, with: secondaryStroke, style: thinStyle)

        case "SW.10": // HIDE DESKTOP ICONS: 2x3 File Matrix + Cloak Slash
            for row in 0..<2 {
                for col in 0..<3 {
                    let x = center.x - r * 0.56 + CGFloat(col) * r * 0.44
                    let y = center.y - r * 0.36 + CGFloat(row) * r * 0.46
                    let cell = CGRect(x: x, y: y, width: r * 0.26, height: r * 0.26)
                    context.fill(Path(roundedRect: cell, cornerRadius: 1.5), with: accentFill)
                    context.stroke(Path(roundedRect: cell, cornerRadius: 1.5), with: primaryStroke, style: thinStyle)
                }
            }
            var slash = Path()
            slash.move(to: CGPoint(x: center.x - r * 0.72, y: center.y + r * 0.62))
            slash.addLine(to: CGPoint(x: center.x + r * 0.72, y: center.y - r * 0.62))
            context.stroke(slash, with: secondaryStroke, style: strokeStyle)

        case "SW.11": // SHOW HIDDEN FILES: Folder + Optical Eye
            let folderRect = CGRect(x: center.x - r * 0.74, y: center.y - r * 0.38, width: r * 1.48, height: r * 0.92)
            context.fill(Path(roundedRect: folderRect, cornerRadius: 2.5), with: accentFill)
            context.stroke(Path(roundedRect: folderRect, cornerRadius: 2.5), with: primaryStroke, style: strokeStyle)
            let pupil = CGRect(x: center.x - r * 0.20, y: center.y - r * 0.12, width: r * 0.40, height: r * 0.40)
            context.stroke(Path(ellipseIn: pupil), with: secondaryStroke, style: thinStyle)

        case "SW.12": // HIDE DOCK: Viewport + Floating Dock Pill
            let screen = CGRect(x: center.x - r * 0.76, y: center.y - r * 0.58, width: r * 1.52, height: r * 1.16)
            context.stroke(Path(roundedRect: screen, cornerRadius: 3), with: primaryStroke, style: strokeStyle)
            let dock = CGRect(x: center.x - r * 0.48, y: screen.maxY - r * 0.28, width: r * 0.96, height: r * 0.16)
            context.fill(Path(roundedRect: dock, cornerRadius: 2), with: primaryStroke)

        case "SW.13": // HIDE ACTIVE WINDOWS: Cascading Isometric Frames
            let back = CGRect(x: center.x - r * 0.68, y: center.y - r * 0.56, width: r * 1.05, height: r * 0.76)
            let front = CGRect(x: center.x - r * 0.36, y: center.y - r * 0.22, width: r * 1.05, height: r * 0.76)
            context.stroke(Path(roundedRect: back, cornerRadius: 2.5), with: secondaryStroke, style: thinStyle)
            context.fill(Path(roundedRect: front, cornerRadius: 2.5), with: .color(TactilePalette.obsidianBackground))
            context.fill(Path(roundedRect: front, cornerRadius: 2.5), with: accentFill)
            context.stroke(Path(roundedRect: front, cornerRadius: 2.5), with: primaryStroke, style: strokeStyle)

        case "SW.14": // STAGE MANAGER: Left Strip + Main Stage
            for idx in 0..<3 {
                let y = center.y - r * 0.52 + CGFloat(idx) * r * 0.38
                let thumb = CGRect(x: center.x - r * 0.76, y: y, width: r * 0.30, height: r * 0.24)
                context.fill(Path(roundedRect: thumb, cornerRadius: 1.5), with: primaryStroke)
            }
            let stage = CGRect(x: center.x - r * 0.32, y: center.y - r * 0.52, width: r * 1.08, height: r * 1.04)
            context.fill(Path(roundedRect: stage, cornerRadius: 2.5), with: accentFill)
            context.stroke(Path(roundedRect: stage, cornerRadius: 2.5), with: primaryStroke, style: strokeStyle)

        case "SW.15": // HIDE DESKTOP WIDGETS: Modular Bento Tiles
            let leftCard = CGRect(x: center.x - r * 0.72, y: center.y - r * 0.54, width: r * 0.66, height: r * 1.08)
            let topRight = CGRect(x: center.x + r * 0.06, y: center.y - r * 0.54, width: r * 0.66, height: r * 0.48)
            let botRight = CGRect(x: center.x + r * 0.06, y: center.y + r * 0.06, width: r * 0.66, height: r * 0.48)
            context.fill(Path(roundedRect: leftCard, cornerRadius: 2.5), with: accentFill)
            context.stroke(Path(roundedRect: leftCard, cornerRadius: 2.5), with: primaryStroke, style: strokeStyle)
            context.stroke(Path(roundedRect: topRight, cornerRadius: 2.5), with: secondaryStroke, style: thinStyle)
            context.stroke(Path(roundedRect: botRight, cornerRadius: 2.5), with: primaryStroke, style: strokeStyle)

        case "SW.16": // MUTE MICROPHONE: Studio Capsule + Yoke + Slash
            let capsule = CGRect(x: center.x - r * 0.26, y: center.y - r * 0.68, width: r * 0.52, height: r * 0.84)
            context.fill(Path(roundedRect: capsule, cornerRadius: r * 0.26), with: accentFill)
            context.stroke(Path(roundedRect: capsule, cornerRadius: r * 0.26), with: primaryStroke, style: strokeStyle)
            var yoke = Path()
            yoke.addArc(
                center: CGPoint(x: center.x, y: center.y - r * 0.18),
                radius: r * 0.46,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false
            )
            yoke.move(to: CGPoint(x: center.x, y: center.y + r * 0.28))
            yoke.addLine(to: CGPoint(x: center.x, y: center.y + r * 0.66))
            yoke.move(to: CGPoint(x: center.x - r * 0.34, y: center.y + r * 0.66))
            yoke.addLine(to: CGPoint(x: center.x + r * 0.34, y: center.y + r * 0.66))
            context.stroke(yoke, with: primaryStroke, style: strokeStyle)

            var slash = Path()
            slash.move(to: CGPoint(x: center.x - r * 0.66, y: center.y + r * 0.56))
            slash.addLine(to: CGPoint(x: center.x + r * 0.66, y: center.y - r * 0.56))
            context.stroke(slash, with: secondaryStroke, style: strokeStyle)

        case "SW.17": // CONNECT AIRPODS: Dual Acoustic Stems + RF Waves
            for side in [-1.0, 1.0] {
                let cx = center.x + CGFloat(side) * r * 0.32
                let head = CGRect(x: cx - r * 0.22, y: center.y - r * 0.52, width: r * 0.44, height: r * 0.38)
                context.fill(Path(ellipseIn: head), with: accentFill)
                context.stroke(Path(ellipseIn: head), with: primaryStroke, style: strokeStyle)
                var stem = Path()
                let stemX = cx + CGFloat(side) * r * 0.08
                stem.move(to: CGPoint(x: stemX, y: head.maxY))
                stem.addLine(to: CGPoint(x: stemX, y: center.y + r * 0.56))
                context.stroke(stem, with: primaryStroke, style: strokeStyle)
            }

        case "SW.18": // PLAY / PAUSE MUSIC: Acoustic Equalizer Bars + Play Prism
            let heights: [CGFloat] = [0.42, 0.85, 1.22, 0.72, 0.46]
            for (idx, h) in heights.enumerated() {
                let x = center.x - r * 0.64 + CGFloat(idx) * r * 0.32
                let barHeight = r * h
                var bar = Path()
                bar.move(to: CGPoint(x: x, y: center.y - barHeight / 2))
                bar.addLine(to: CGPoint(x: x, y: center.y + barHeight / 2))
                context.stroke(bar, with: idx == 2 ? primaryStroke : secondaryStroke, style: strokeStyle)
            }

        case "SW.19": // SCREEN CLEAN: Viewport + Optical Wiper Arc
            let screen = CGRect(x: center.x - r * 0.76, y: center.y - r * 0.54, width: r * 1.52, height: r * 1.08)
            context.stroke(Path(roundedRect: screen, cornerRadius: 3), with: primaryStroke, style: strokeStyle)
            var wiper = Path()
            let pivot = CGPoint(x: center.x, y: screen.maxY - 2)
            wiper.addArc(
                center: pivot,
                radius: r * 0.72,
                startAngle: .degrees(215),
                endAngle: .degrees(325),
                clockwise: false
            )
            wiper.move(to: pivot)
            wiper.addLine(to: CGPoint(x: center.x + r * 0.36, y: screen.minY + r * 0.22))
            context.stroke(wiper, with: secondaryStroke, style: thinStyle)

        case "SW.20": // LOCK KEYBOARD: Mechanical Keycap + Shackle
            let keycap = CGRect(x: center.x - r * 0.72, y: center.y - r * 0.22, width: r * 1.44, height: r * 0.82)
            context.fill(Path(roundedRect: keycap, cornerRadius: 3), with: accentFill)
            context.stroke(Path(roundedRect: keycap, cornerRadius: 3), with: primaryStroke, style: strokeStyle)
            var shackle = Path()
            shackle.addArc(
                center: CGPoint(x: center.x, y: keycap.minY),
                radius: r * 0.32,
                startAngle: .degrees(180),
                endAngle: .degrees(360),
                clockwise: false
            )
            context.stroke(shackle, with: secondaryStroke, style: strokeStyle)

        case "SW.21": // LOCK SCREEN: Armored Shield + Keyhole
            var shield = Path()
            shield.move(to: CGPoint(x: center.x, y: center.y - r * 0.74))
            shield.addLine(to: CGPoint(x: center.x + r * 0.62, y: center.y - r * 0.46))
            shield.addLine(to: CGPoint(x: center.x + r * 0.52, y: center.y + r * 0.22))
            shield.addLine(to: CGPoint(x: center.x, y: center.y + r * 0.74))
            shield.addLine(to: CGPoint(x: center.x - r * 0.52, y: center.y + r * 0.22))
            shield.addLine(to: CGPoint(x: center.x - r * 0.62, y: center.y - r * 0.46))
            shield.closeSubpath()
            context.fill(shield, with: accentFill)
            context.stroke(shield, with: primaryStroke, style: strokeStyle)
            let keyhole = CGRect(x: center.x - r * 0.14, y: center.y - r * 0.16, width: r * 0.28, height: r * 0.28)
            context.fill(Path(ellipseIn: keyhole), with: primaryStroke)

        case "SW.22": // EMPTY TRASH: Industrial Cylinder + Flutes
            var bin = Path()
            bin.move(to: CGPoint(x: center.x - r * 0.56, y: center.y - r * 0.36))
            bin.addLine(to: CGPoint(x: center.x + r * 0.56, y: center.y - r * 0.36))
            bin.addLine(to: CGPoint(x: center.x + r * 0.44, y: center.y + r * 0.68))
            bin.addLine(to: CGPoint(x: center.x - r * 0.44, y: center.y + r * 0.68))
            bin.closeSubpath()
            context.fill(bin, with: accentFill)
            context.stroke(bin, with: primaryStroke, style: strokeStyle)

            var lid = Path()
            lid.move(to: CGPoint(x: center.x - r * 0.68, y: center.y - r * 0.52))
            lid.addLine(to: CGPoint(x: center.x + r * 0.68, y: center.y - r * 0.52))
            context.stroke(lid, with: secondaryStroke, style: strokeStyle)

        case "SW.23": // CLEAR PASTEBOARD: Clipboard Chassis + Spark
            let board = CGRect(x: center.x - r * 0.58, y: center.y - r * 0.54, width: r * 1.16, height: r * 1.22)
            context.fill(Path(roundedRect: board, cornerRadius: 2.5), with: accentFill)
            context.stroke(Path(roundedRect: board, cornerRadius: 2.5), with: primaryStroke, style: strokeStyle)
            let clip = CGRect(x: center.x - r * 0.28, y: board.minY - r * 0.14, width: r * 0.56, height: r * 0.24)
            context.fill(Path(roundedRect: clip, cornerRadius: 1.5), with: primaryStroke)
            drawFourPointStar(in: &context, center: CGPoint(x: center.x, y: center.y + r * 0.10), radius: r * 0.28)

        case "SW.24": // EJECT DISKS: Precision ISO Eject Delta + Base Bar
            var triangle = Path()
            triangle.move(to: CGPoint(x: center.x, y: center.y - r * 0.58))
            triangle.addLine(to: CGPoint(x: center.x + r * 0.58, y: center.y + r * 0.12))
            triangle.addLine(to: CGPoint(x: center.x - r * 0.58, y: center.y + r * 0.12))
            triangle.closeSubpath()
            context.fill(triangle, with: accentFill)
            context.stroke(triangle, with: primaryStroke, style: strokeStyle)

            let bar = CGRect(x: center.x - r * 0.58, y: center.y + r * 0.34, width: r * 1.16, height: r * 0.20)
            context.fill(Path(roundedRect: bar, cornerRadius: 1.5), with: primaryStroke)

        case "SW.25": // CLEAN XCODE CACHE: Hammer Schematic + Cache Stack
            var handle = Path()
            handle.move(to: CGPoint(x: center.x - r * 0.52, y: center.y + r * 0.56))
            handle.addLine(to: CGPoint(x: center.x + r * 0.28, y: center.y - r * 0.24))
            context.stroke(handle, with: primaryStroke, style: strokeStyle)

            var head = Path()
            head.move(to: CGPoint(x: center.x + r * 0.02, y: center.y - r * 0.52))
            head.addLine(to: CGPoint(x: center.x + r * 0.56, y: center.y + r * 0.02))
            context.stroke(head, with: secondaryStroke, style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
            drawFourPointStar(in: &context, center: CGPoint(x: center.x - r * 0.36, y: center.y - r * 0.32), radius: r * 0.22)

        default: // SW.26 DO NOT DISTURB: Crescent Moon + Silenced Wave
            var crescent = Path()
            crescent.addArc(
                center: CGPoint(x: center.x - r * 0.08, y: center.y),
                radius: r * 0.58,
                startAngle: .degrees(40),
                endAngle: .degrees(300),
                clockwise: false
            )
            context.fill(crescent, with: accentFill)
            context.stroke(crescent, with: primaryStroke, style: strokeStyle)
            drawFourPointStar(in: &context, center: CGPoint(x: center.x + r * 0.38, y: center.y - r * 0.28), radius: r * 0.20)
        }
    }

    private func drawMonitorFrame(
        in context: inout GraphicsContext,
        center: CGPoint,
        r: CGFloat,
        strokeStyle: StrokeStyle
    ) {
        let screenRect = CGRect(x: center.x - r * 0.76, y: center.y - r * 0.56, width: r * 1.52, height: r * 0.92)
        let screenPath = Path(roundedRect: screenRect, cornerRadius: 3)
        context.fill(screenPath, with: accentFill)
        context.stroke(screenPath, with: primaryStroke, style: strokeStyle)

        var stand = Path()
        stand.move(to: CGPoint(x: center.x, y: screenRect.maxY))
        stand.addLine(to: CGPoint(x: center.x, y: screenRect.maxY + r * 0.26))
        stand.move(to: CGPoint(x: center.x - r * 0.38, y: screenRect.maxY + r * 0.26))
        stand.addLine(to: CGPoint(x: center.x + r * 0.38, y: screenRect.maxY + r * 0.26))
        context.stroke(stand, with: primaryStroke, style: strokeStyle)
    }

    private func drawFourPointStar(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        var star = Path()
        star.move(to: CGPoint(x: center.x, y: center.y - radius))
        star.addQuadCurve(
            to: CGPoint(x: center.x + radius, y: center.y),
            control: center
        )
        star.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + radius),
            control: center
        )
        star.addQuadCurve(
            to: CGPoint(x: center.x - radius, y: center.y),
            control: center
        )
        star.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y - radius),
            control: center
        )
        context.fill(star, with: primaryStroke)
    }
}
