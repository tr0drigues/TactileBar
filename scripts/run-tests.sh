#!/usr/bin/env bash
set -euo pipefail

# Caminhos abaixo são relativos à raiz do pacote, de onde quer que o script seja chamado.
cd "$(dirname "$0")/.."

CACHE_DIR="${TMPDIR:-/tmp}/tactilebar-swift-cache"
BUILD_DIR=".build/release"

if [ ! -f "${BUILD_DIR}/libTactileCore.a" ]; then
    ./scripts/build-app.sh
fi

echo "==> Running TactileBar verification suite..."
TEST_BIN="${BUILD_DIR}/TactileBarTestRunner"

cat > "${BUILD_DIR}/TestMain.swift" <<'EOF'
import Foundation
import SwitchCatalog
import TactileCore

@main
struct TestRunner {
    @MainActor
    static func main() async {
        print("1. Verificando catálogo de 26 interruptores...")
        let switches = TactileSwitchCatalog.makeAllSwitches()
        precondition(switches.count == AppConfiguration.totalCatalogSwitchCount, "Contagem incorreta de switches")
        precondition(Set(switches.map(\.id)).count == 26, "IDs duplicados detectados")
        precondition(switches.first?.id == "SW.01" && switches.last?.id == "SW.26", "Limites do catálogo inválidos")
        print("   [OK] 26 switches únicos (SW.01 .. SW.26) validados.")

        print("2. Verificando distribuição por domínio...")
        precondition(switches.filter { $0.domain == .power }.count == 5, "Domínio PWR inválido")
        precondition(switches.filter { $0.domain == .optics }.count == 4, "Domínio OPT inválido")
        precondition(switches.filter { $0.domain == .workspace }.count == 6, "Domínio WKS inválido")
        precondition(switches.filter { $0.domain == .signal }.count == 3, "Domínio SIG inválido")
        precondition(switches.filter { $0.domain == .security }.count == 8, "Domínio SEC inválido")
        print("   [OK] Distribuição (5 PWR, 4 OPT, 6 WKS, 3 SIG, 8 SEC) validada.")

        print("3. Verificando filtragem e busca no SwitchRegistry...")
        let registry = SwitchRegistry(switches: switches)
        registry.selectedDomainFilter = .signal
        precondition(registry.filteredSwitches.count == 3, "Filtro de domínio falhou")
        registry.selectedDomainFilter = nil
        registry.searchQuery = "XCODE"
        precondition(registry.filteredSwitches.first?.id == "SW.25", "Busca textual falhou")
        print("   [OK] SwitchRegistry filtrando por domínio e texto corretamente.")

        print("4. Verificando comparador SemVer do GitHubReleaseChecker...")
        precondition(GitHubReleaseChecker.isVersion("1.1.0", newerThan: "1.0.0"), "Falha SemVer 1.1.0 > 1.0.0")
        precondition(!GitHubReleaseChecker.isVersion("1.0.0", newerThan: "1.0.0"), "Falha SemVer igualdade")
        print("   [OK] Comparador SemVer validado.")

        print("5. Verificando gerador nativo de QR Code (CoreImage) para GitHub Sponsors...")
        let qr = QRCodeGeneratorService.generateCGImage(from: AppConfiguration.sponsorURL, dimension: 120)
        precondition(qr != nil && qr?.width == 120 && qr?.height == 120, "Falha na geração do QR Code")
        print("   [OK] QR Code 120x120 gerado para \(AppConfiguration.sponsorURL.absoluteString).")

        print("6. Verificando geometria do anel radial (8 posições, cardeais primeiro)...")
        precondition(RingGeometry.slot(dx: 0, dy: -100, deadZoneRadius: 59) == 0, "Topo deve ser rank 0")
        precondition(RingGeometry.slot(dx: 100, dy: 0, deadZoneRadius: 59) == 1, "Direita deve ser rank 1")
        precondition(RingGeometry.slot(dx: 0, dy: 100, deadZoneRadius: 59) == 2, "Baixo deve ser rank 2")
        precondition(RingGeometry.slot(dx: -100, dy: 0, deadZoneRadius: 59) == 3, "Esquerda deve ser rank 3")
        precondition(RingGeometry.slot(dx: 70, dy: -70, deadZoneRadius: 59) == 4, "Nordeste deve ser rank 4")
        precondition(RingGeometry.slot(dx: -70, dy: -70, deadZoneRadius: 59) == 7, "Noroeste deve ser rank 7")
        precondition(RingGeometry.slot(dx: 20, dy: 72, deadZoneRadius: 59) == 2, "20° do sul ainda é sul")
        precondition(RingGeometry.slot(dx: 30, dy: 20, deadZoneRadius: 59) == nil, "Zona morta deve retornar nil")
        precondition(RingGeometry.slot(dx: 0, dy: 0, deadZoneRadius: 59) == nil, "Vetor nulo deve retornar nil")
        print("   [OK] Posições cardeais, diagonais e zona morta validadas.")

        print("7. Verificando ordem do anel por uso (estável)...")
        let pins = ["SW.01", "SW.06", "SW.10", "SW.16"]
        let ranked = RingOrdering.rankedByUsage(pinnedOrder: pins, usageCounts: ["SW.16": 9, "SW.06": 3, "SW.10": 3])
        precondition(ranked == ["SW.16", "SW.06", "SW.10", "SW.01"], "Ordem por uso ou desempate incorretos")
        let firstLayout = RingOrdering.layout(ranked: ranked)
        precondition(firstLayout.count == 8 && firstLayout[0] == "SW.16" && firstLayout[7] == nil, "Layout inicial inválido")
        let afterRemoval = RingOrdering.reconcile(slots: firstLayout, pinnedOrder: ["SW.01", "SW.10", "SW.16"], usageCounts: [:])
        precondition(afterRemoval[0] == "SW.16" && afterRemoval[1] == nil && afterRemoval[2] == "SW.10", "Remover pin não pode mover os outros")
        let afterAdd = RingOrdering.reconcile(slots: afterRemoval, pinnedOrder: ["SW.01", "SW.10", "SW.16", "SW.22"], usageCounts: [:])
        precondition(afterAdd[1] == "SW.22" && afterAdd[0] == "SW.16", "Novo pin deve ocupar a primeira posição livre")
        let crowded = (1...10).map { String(format: "SW.%02d", $0) }
        let crowdedLayout = RingOrdering.layout(ranked: crowded)
        precondition(RingOrdering.overflowCount(slots: crowdedLayout, pinnedOrder: crowded) == 2, "Excedente acima de 8 pins incorreto")
        print("   [OK] Ranking, desempate, estabilidade e excedente validados.")

        print("8. Verificando sessão do anel (segurar, fixar, cancelar, armar)...")
        let entries: [RingSlotEntry?] = [
            RingSlotEntry(switchID: "SW.16", isDestructive: false, isActionable: true),
            RingSlotEntry(switchID: "SW.25", isDestructive: true, isActionable: true),
            nil, nil, nil, nil, nil, nil
        ]
        var session = RingSession(deadZoneRadius: 59)
        session.open(slots: entries, at: 0)
        session.pointerMoved(dx: 0, dy: -100, at: 0.1)
        precondition(session.hotKeyReleased(at: 0.4) == .fire(switchID: "SW.16"), "Segurar, mover e soltar deve acionar")
        session.open(slots: entries, at: 10)
        session.pointerMoved(dx: 0, dy: -100, at: 10.02)
        precondition(session.hotKeyReleased(at: 10.08) == .dismiss, "Soltar rápido demais deve cancelar")
        session.open(slots: entries, at: 20)
        precondition(session.hotKeyReleased(at: 20.1) == .none && session.phase == .latched, "Toque rápido deve fixar o anel")
        precondition(session.cancel() == .dismiss && !session.isOpen, "Esc deve fechar o anel fixo")
        session.open(slots: entries, at: 30)
        session.pointerMoved(dx: 100, dy: 0, at: 30.3)
        precondition(session.hotKeyReleased(at: 30.4) == .dismiss, "Destrutivo sem armar deve cancelar")
        session.open(slots: entries, at: 40)
        session.pointerMoved(dx: 100, dy: 0, at: 40.3)
        precondition(session.hotKeyReleased(at: 40.7) == .fire(switchID: "SW.25"), "Destrutivo armado deve acionar")
        session.open(slots: entries, at: 50)
        session.pointerMoved(dx: 0, dy: 100, at: 50.3)
        precondition(session.focusedSlot == nil, "Posição vazia não recebe foco")
        precondition(session.hotKeyReleased(at: 50.5) == .dismiss, "Soltar sem foco após mover deve cancelar")
        print("   [OK] Disparo, cancelamento, modo fixo e armamento validados.")

        print("9. Verificando contagem de uso e ordem dos pins no SwitchRegistry...")
        let ringSuite = "studio.tactile.TactileBarRunner.\(UUID().uuidString)"
        let ringDefaults = UserDefaults(suiteName: ringSuite)!
        ringDefaults.set(["SW.16", "SW.01"], forKey: SwitchRegistry.pinnedSwitchesStorageKey)
        let ringRegistry = SwitchRegistry(switches: switches, userDefaults: ringDefaults)
        precondition(ringRegistry.pinnedOrder == ["SW.16", "SW.01"], "Pins salvos devem manter a ordem")
        precondition(ringRegistry.ringSlots[0] == "SW.16", "Sem histórico, o anel segue a ordem dos pins")
        ringRegistry.togglePin(forSwitchID: "SW.06")
        precondition(ringRegistry.ringSlots[2] == "SW.06" && ringRegistry.pinnedOrder.last == "SW.06", "Novo pin entra no fim e na primeira posição livre")
        ringDefaults.removePersistentDomain(forName: ringSuite)
        print("   [OK] Ordem dos pins e posições do anel persistidas.")

        print("10. Verificando leque de escolhas (Bluetooth) no anel...")
        precondition(RingGeometry.choiceAngles(count: 3, aroundSlot: 3) == [159, 180, 201], "Leque deve centrar na fatia")
        precondition(RingGeometry.choice(dx: 160, dy: 0, count: 3, aroundSlot: 3) == nil, "Fora do leque não aponta escolha")
        let choiceEntries: [RingSlotEntry?] = [
            RingSlotEntry(switchID: "SW.16", isDestructive: false, isActionable: true),
            nil, nil,
            RingSlotEntry(switchID: "SW.17", isDestructive: false, isActionable: true, choiceIDs: ["A", "B", "C"]),
            nil, nil, nil, nil
        ]
        var fan = RingSession(deadZoneRadius: 59, expandRadius: 133)
        fan.open(slots: choiceEntries, at: 0)
        fan.pointerMoved(dx: -100, dy: 0, at: 0.1)
        precondition(fan.expandedSlot == nil && fan.hotKeyReleased(at: 0.3) == .fire(switchID: "SW.17"), "Soltar na fatia usa o preferido")
        fan.open(slots: choiceEntries, at: 10)
        fan.pointerMoved(dx: -100, dy: 0, at: 10.1)
        fan.pointerMoved(dx: -160, dy: 0, at: 10.2)
        precondition(fan.expandedSlot == 3 && fan.focusedChoice == 1, "Empurrar além da borda abre o leque")
        fan.pointerMoved(dx: 0, dy: 10, at: 10.3)
        precondition(fan.expandedSlot == nil && fan.focusedSlot == nil, "Voltar ao centro fecha o leque")
        fan.pointerMoved(dx: 160 * cos(201 * Double.pi / 180), dy: 160 * sin(201 * Double.pi / 180), at: 10.4)
        precondition(fan.hotKeyReleased(at: 10.5) == .fireChoice(switchID: "SW.17", choiceID: "C"), "Soltar na escolha aciona ela")
        fan.open(slots: choiceEntries, at: 20)
        fan.pointerMoved(dx: -100, dy: 0, at: 20.1)
        fan.advance(to: 20.3)
        precondition(fan.expandedSlot == nil, "Leque não abre antes do tempo")
        fan.advance(to: 20.6)
        precondition(fan.expandedSlot == 3 && fan.focusedChoice == nil, "Parar sobre a fatia abre o leque")
        precondition(fan.hotKeyReleased(at: 20.7) == .fire(switchID: "SW.17"), "Leque aberto sem escolha usa o preferido")
        fan.open(slots: choiceEntries, at: 30)
        _ = fan.hotKeyReleased(at: 30.1)
        fan.select(slot: 3, at: 30.2)
        fan.toggleExpansion()
        fan.rotateFocus(clockwise: true, at: 30.3)
        precondition(fan.focusedChoice == 1, "Setas percorrem as escolhas")
        fan.collapse()
        fan.advance(to: 35)
        precondition(fan.expandedSlot == nil && fan.focusedSlot == 3, "Esc fecha o leque e não reabre sozinho")
        fan.toggleExpansion()
        fan.select(choice: 2)
        precondition(fan.confirm(at: 35.1) == .fireChoice(switchID: "SW.17", choiceID: "C"), "Tecla de escolha confirma no modo fixo")
        print("   [OK] Leque por empurrão, por tempo, teclado e Esc validados.")

        print("\n==> TODOS OS TESTES PASSARAM COM SUCESSO!")
    }
}
EOF

swiftc -module-cache-path "${CACHE_DIR}" -O -swift-version 6 \
    -parse-as-library \
    -I "${BUILD_DIR}" \
    "${BUILD_DIR}/libTactileCore.a" \
    "${BUILD_DIR}/libSystemAdapters.a" \
    "${BUILD_DIR}/libSwitchCatalog.a" \
    -o "${TEST_BIN}" \
    "${BUILD_DIR}/TestMain.swift"

"${TEST_BIN}"
rm -f "${BUILD_DIR}/TestMain.swift" "${TEST_BIN}"
