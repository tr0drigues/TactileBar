import AppKit
import SwiftUI

public enum MenuBarTelemetryIcon {
    @MainActor
    private static var statusBarImageCache: [Int: NSImage] = [:]

    @MainActor
    public static func makeStatusBarImage(activeCount: Int) -> NSImage {
        let clampedCount = max(0, min(activeCount, 99))
        if let cached = statusBarImageCache[clampedCount] {
            return cached
        }

        let hasBadge = clampedCount > 0
        let width: CGFloat = hasBadge ? 40.0 : 20.0
        let height: CGFloat = 18.0
        let size = NSSize(width: width, height: height)

        let image = NSImage(size: size, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.setAllowsAntialiasing(true)
            ctx.setShouldAntialias(true)

            let obsidian = NSColor(srgbRed: 11.0 / 255.0, green: 13.0 / 255.0, blue: 16.0 / 255.0, alpha: 0.92).cgColor
            let ivory = NSColor(srgbRed: 236.0 / 255.0, green: 232.0 / 255.0, blue: 223.0 / 255.0, alpha: 0.96).cgColor
            let amber = NSColor(srgbRed: 245.0 / 255.0, green: 158.0 / 255.0, blue: 11.0 / 255.0, alpha: 1.0).cgColor
            let cyan = NSColor(srgbRed: 56.0 / 255.0, green: 189.0 / 255.0, blue: 248.0 / 255.0, alpha: 1.0).cgColor
            let muted = NSColor(srgbRed: 156.0 / 255.0, green: 166.0 / 255.0, blue: 182.0 / 255.0, alpha: 0.75).cgColor

            // 1. Horological Telemetry Dial Glyph (Left 18x18)
            let dialCenter = CGPoint(x: 9.5, y: 9.0)
            let outerR: CGFloat = 7.4
            let innerR: CGFloat = 4.6

            // Dark obsidian dial well
            let wellRect = CGRect(
                x: dialCenter.x - outerR,
                y: dialCenter.y - outerR,
                width: outerR * 2,
                height: outerR * 2
            )
            ctx.setFillColor(obsidian)
            ctx.fillEllipse(in: wellRect)

            // Outer bezel ring
            ctx.setStrokeColor(hasBadge ? amber : ivory)
            ctx.setLineWidth(1.35)
            ctx.strokeEllipse(in: wellRect)

            // 8 Radial Graduation Ticks around the bezel
            for tick in 0..<8 {
                let angle = CGFloat(tick) * (.pi / 4.0)
                let r1: CGFloat = (tick % 2 == 0) ? (outerR - 2.3) : (outerR - 1.6)
                let r2: CGFloat = outerR - 0.5
                ctx.move(to: CGPoint(
                    x: dialCenter.x + cos(angle) * r1,
                    y: dialCenter.y + sin(angle) * r1
                ))
                ctx.addLine(to: CGPoint(
                    x: dialCenter.x + cos(angle) * r2,
                    y: dialCenter.y + sin(angle) * r2
                ))
                ctx.setStrokeColor((tick % 2 == 0) ? ivory : muted)
                ctx.setLineWidth((tick % 2 == 0) ? 1.1 : 0.8)
                ctx.strokePath()
            }

            // Inner Cyan Telemetry Arc (240° sweep)
            ctx.addArc(
                center: dialCenter,
                radius: innerR,
                startAngle: -.pi * 0.25,
                endAngle: .pi * 1.15,
                clockwise: false
            )
            ctx.setStrokeColor(hasBadge ? cyan : muted)
            ctx.setLineWidth(1.4)
            ctx.setLineCap(.round)
            ctx.strokePath()

            // Precision Gauge Needle + Center Hub
            let needleAngle: CGFloat = hasBadge ? (.pi * 0.25) : (.pi * 0.65)
            ctx.move(to: dialCenter)
            ctx.addLine(to: CGPoint(
                x: dialCenter.x + cos(needleAngle) * (outerR - 2.0),
                y: dialCenter.y + sin(needleAngle) * (outerR - 2.0)
            ))
            ctx.setStrokeColor(amber)
            ctx.setLineWidth(1.45)
            ctx.setLineCap(.round)
            ctx.strokePath()

            let hubRect = CGRect(x: dialCenter.x - 1.6, y: dialCenter.y - 1.6, width: 3.2, height: 3.2)
            ctx.setFillColor(ivory)
            ctx.fillEllipse(in: hubRect)

            // 2. Active Telemetry Count Pill Badge (if activeCount > 0)
            if hasBadge {
                let pillRect = CGRect(x: 19.5, y: 2.5, width: 19.5, height: 13.0)
                let pillPath = CGPath(roundedRect: pillRect, cornerWidth: 3.5, cornerHeight: 3.5, transform: nil)
                ctx.addPath(pillPath)
                ctx.setFillColor(obsidian)
                ctx.fillPath()

                ctx.addPath(pillPath)
                ctx.setStrokeColor(amber)
                ctx.setLineWidth(1.1)
                ctx.strokePath()

                let badgeText = String(format: "%02d", activeCount) as NSString
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedDigitSystemFont(ofSize: 9.0, weight: .bold),
                    .foregroundColor: NSColor(srgbRed: 245.0 / 255.0, green: 158.0 / 255.0, blue: 11.0 / 255.0, alpha: 1.0),
                    .paragraphStyle: paragraph
                ]
                let textSize = badgeText.size(withAttributes: attrs)
                let textRect = CGRect(
                    x: pillRect.origin.x,
                    y: pillRect.origin.y + (pillRect.height - textSize.height) / 2.0 - 0.5,
                    width: pillRect.width,
                    height: textSize.height
                )
                badgeText.draw(in: textRect, withAttributes: attrs)
            }

            return true
        }

        image.isTemplate = false
        statusBarImageCache[clampedCount] = image
        return image
    }

    @MainActor
    public static func makeApplicationIconImage(dimension: CGFloat = 512.0) -> NSImage {
        let size = NSSize(width: dimension, height: dimension)
        return NSImage(size: size, flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.setAllowsAntialiasing(true)
            ctx.setShouldAntialias(true)

            let s = dimension
            let center = CGPoint(x: s / 2.0, y: s / 2.0)

            let obsidian = NSColor(srgbRed: 11.0 / 255.0, green: 13.0 / 255.0, blue: 16.0 / 255.0, alpha: 1.0).cgColor
            let graphite = NSColor(srgbRed: 20.0 / 255.0, green: 25.0 / 255.0, blue: 35.0 / 255.0, alpha: 1.0).cgColor
            let steel = NSColor(srgbRed: 64.0 / 255.0, green: 76.0 / 255.0, blue: 98.0 / 255.0, alpha: 1.0).cgColor
            let ivory = NSColor(srgbRed: 236.0 / 255.0, green: 232.0 / 255.0, blue: 223.0 / 255.0, alpha: 1.0).cgColor
            let amber = NSColor(srgbRed: 245.0 / 255.0, green: 158.0 / 255.0, blue: 11.0 / 255.0, alpha: 1.0).cgColor
            let cyan = NSColor(srgbRed: 56.0 / 255.0, green: 189.0 / 255.0, blue: 248.0 / 255.0, alpha: 1.0).cgColor
            let emerald = NSColor(srgbRed: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0, alpha: 1.0).cgColor
            let orange = NSColor(srgbRed: 255.0 / 255.0, green: 87.0 / 255.0, blue: 34.0 / 255.0, alpha: 1.0).cgColor

            // macOS Squircle Chassis
            let pad = s * 0.08
            let chassisRect = CGRect(x: pad, y: pad, width: s - pad * 2, height: s - pad * 2)
            let chassisPath = CGPath(roundedRect: chassisRect, cornerWidth: s * 0.19, cornerHeight: s * 0.19, transform: nil)
            ctx.addPath(chassisPath)
            ctx.setFillColor(obsidian)
            ctx.fillPath()

            ctx.addPath(chassisPath)
            ctx.setStrokeColor(steel)
            ctx.setLineWidth(s * 0.014)
            ctx.strokePath()

            // Outer Horological Bezel Ring
            let rOuter = s * 0.35
            let bezelRect = CGRect(x: center.x - rOuter, y: center.y - rOuter, width: rOuter * 2, height: rOuter * 2)
            ctx.setFillColor(graphite)
            ctx.fillEllipse(in: bezelRect)
            ctx.setStrokeColor(steel)
            ctx.setLineWidth(s * 0.01)
            ctx.strokeEllipse(in: bezelRect)

            // 26 Radial Telemetry Segments
            let sectorR = s * 0.27
            let step = (2.0 * CGFloat.pi) / 26.0
            let palette = [amber, cyan, ivory, emerald, orange]
            for i in 0..<26 {
                let a1 = CGFloat(i) * step
                let a2 = a1 + step * 0.72
                ctx.addArc(center: center, radius: sectorR, startAngle: a1, endAngle: a2, clockwise: false)
                ctx.setStrokeColor(palette[i % palette.count])
                ctx.setLineWidth(s * 0.038)
                ctx.setLineCap(.butt)
                ctx.strokePath()
            }

            // Inner Core Hub + Needle
            let rCore = s * 0.14
            let coreRect = CGRect(x: center.x - rCore, y: center.y - rCore, width: rCore * 2, height: rCore * 2)
            ctx.setFillColor(obsidian)
            ctx.fillEllipse(in: coreRect)
            ctx.setStrokeColor(amber)
            ctx.setLineWidth(s * 0.012)
            ctx.strokeEllipse(in: coreRect)

            ctx.move(to: center)
            ctx.addLine(to: CGPoint(x: center.x + rOuter * 0.62, y: center.y + rOuter * 0.52))
            ctx.setStrokeColor(amber)
            ctx.setLineWidth(s * 0.022)
            ctx.setLineCap(.round)
            ctx.strokePath()

            let pinR = s * 0.028
            ctx.setFillColor(ivory)
            ctx.fillEllipse(in: CGRect(x: center.x - pinR, y: center.y - pinR, width: pinR * 2, height: pinR * 2))

            return true
        }
    }
}
