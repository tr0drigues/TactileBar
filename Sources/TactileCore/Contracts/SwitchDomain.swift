import Foundation

public enum SwitchDomain: String, CaseIterable, Codable, Sendable, Identifiable {
    case power = "PWR"
    case optics = "OPT"
    case workspace = "WKS"
    case signal = "SIG"
    case security = "SEC"

    public var id: String { rawValue }

    public var shortCode: String { rawValue }

    public var fullHeaderTitle: String {
        switch self {
        case .power: return "M.01 // POWER & SLEEP"
        case .optics: return "M.02 // OPTICS & LUMINANCE"
        case .workspace: return "M.03 // SPATIAL WORKSPACE"
        case .signal: return "M.04 // ACOUSTIC & RF SIGNAL"
        case .security: return "M.05 // SECURITY & PURGE"
        }
    }
}

public enum SwitchExecutionState: Equatable, Sendable {
    case off(statusText: String)
    case on(statusText: String)
    case busy(progressText: String)
    case unsupported(reason: String)
    case permissionRequired(settingsURL: URL)

    public var isEnabled: Bool {
        if case .on = self { return true }
        return false
    }

    public var statusSubtitle: String {
        switch self {
        case .off(let text), .on(let text), .busy(let text), .unsupported(let text):
            return text
        case .permissionRequired:
            return "GRANT PERMISSION"
        }
    }
}
