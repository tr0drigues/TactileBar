import SwiftUI
import TactileCore

public enum TactilePalette {
    public static let obsidianBackground = Color(red: 11.0 / 255.0, green: 13.0 / 255.0, blue: 16.0 / 255.0)
    public static let graphitePanel = Color(red: 18.0 / 255.0, green: 22.0 / 255.0, blue: 30.0 / 255.0)
    public static let elevatedPanel = Color(red: 23.0 / 255.0, green: 28.0 / 255.0, blue: 38.0 / 255.0)
    public static let hairlineSubtle = Color(red: 28.0 / 255.0, green: 34.0 / 255.0, blue: 46.0 / 255.0)
    public static let gridLine = Color(red: 42.0 / 255.0, green: 50.0 / 255.0, blue: 66.0 / 255.0)
    public static let borderSteel = Color(red: 64.0 / 255.0, green: 76.0 / 255.0, blue: 98.0 / 255.0)

    public static let ivoryText = Color(red: 236.0 / 255.0, green: 232.0 / 255.0, blue: 223.0 / 255.0)
    public static let silverMuted = Color(red: 156.0 / 255.0, green: 166.0 / 255.0, blue: 182.0 / 255.0)
    public static let slateDim = Color(red: 96.0 / 255.0, green: 108.0 / 255.0, blue: 128.0 / 255.0)

    public static let tungstenAmber = Color(red: 245.0 / 255.0, green: 158.0 / 255.0, blue: 11.0 / 255.0)
    public static let internationalOrange = Color(red: 255.0 / 255.0, green: 87.0 / 255.0, blue: 34.0 / 255.0)
    public static let oscilloscopeCyan = Color(red: 56.0 / 255.0, green: 189.0 / 255.0, blue: 248.0 / 255.0)
    public static let signalEmerald = Color(red: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0)

    public static func accentColor(for domain: SwitchDomain) -> Color {
        switch domain {
        case .power:
            return tungstenAmber
        case .optics:
            return oscilloscopeCyan
        case .workspace:
            return ivoryText
        case .signal:
            return signalEmerald
        case .security:
            return internationalOrange
        }
    }
}
