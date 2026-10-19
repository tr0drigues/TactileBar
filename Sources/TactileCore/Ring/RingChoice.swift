import Foundation

/// Uma opção dentro de um switch com várias escolhas (ex: um dispositivo Bluetooth pareado).
public struct RingChoice: Identifiable, Equatable, Sendable {
    public let id: String
    /// Nome em caixa-alta exibido no leque.
    public let title: String
    /// Selo curto (ex: "AUDIO", "CTRL").
    public let badge: String
    /// Ligado/conectado agora.
    public let isActive: Bool
    /// Alvo usado quando a fatia é acionada sem abrir o leque.
    public let isPreferred: Bool

    public init(id: String, title: String, badge: String, isActive: Bool, isPreferred: Bool) {
        self.id = id
        self.title = title
        self.badge = badge
        self.isActive = isActive
        self.isPreferred = isPreferred
    }
}
