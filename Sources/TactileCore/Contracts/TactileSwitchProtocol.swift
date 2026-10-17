import Foundation

@MainActor
public protocol TactileSwitchProtocol: AnyObject, Identifiable {
    /// Identificador único de telemetria (ex: "SW.01" a "SW.26").
    var id: String { get }
    /// Nome principal em caixa-alta exibido no cartão (ex: "KEEP AWAKE").
    var title: String { get }
    /// Domínio funcional e cromático ao qual o módulo pertence.
    var domain: SwitchDomain { get }
    /// Nome do símbolo nativo no catálogo SF Symbols da Apple.
    var sfSymbolName: String { get }
    /// Subsistema de baixo nível associado (ex: "IOKit.pwr_mgt").
    var subsystemLabel: String { get }
    /// Estado de execução atual observado pela interface.
    var state: SwitchExecutionState { get }
    /// Define se o botão funciona como gatilho instantâneo (true) ou chave contínua (false).
    var isMomentaryAction: Bool { get }

    /// Executa a alternância de estado ou dispara a ação imediata.
    func trigger() async
    /// Sincroniza o estado do interruptor com o sistema operacional.
    func refreshState() async
}
