#!/usr/bin/env bash
set -euo pipefail

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
