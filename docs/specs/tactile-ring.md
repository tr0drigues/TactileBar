# SPEC — TactileRing (anel radial global)

Status: rascunho v2 (pós-revisão de UX) · Alvo: TactileBar v1.4.0 (experimental) · Plataforma: macOS 14+, Swift 5.10/6 · Dependências externas: nenhuma

Arte de referência: canvas "TactileRing — anel radial" (quadros: anel em contexto, componente, estados).

## 1. Objetivo

Permitir disparar os switches fixados (pinned) sem abrir o popover da barra de menu. Um atalho global abre um **anel radial na posição do cursor**; mover o mouse (ou teclar 1–8) escolhe a fatia; soltar o atalho aciona o switch.

O popover atual **não muda**: o anel é um segundo modo de uso, opcional e desligado por padrão.

## 2. Fora de escopo (v1)

- Alcançar os switches não fixados pelo anel (possível v2: um segundo anel por domínio M.01–M.05).
- Preencher fatias vazias com sugestões automáticas.
- Gatilho por botão extra do mouse (exige `CGEventTap` e Accessibility; possível opção avançada futura).
- Sons e anéis por aplicativo.
- Qualquer reutilização de código, ícones ou sons de outros apps. Tudo é escrito do zero com APIs públicas.

## 3. Premissas do projeto que a feature respeita

- **Zero dependências.** Apenas frameworks do sistema (AppKit, SwiftUI, Carbon para o atalho global).
- **Sem permissão nova por padrão.** O atalho via `RegisterEventHotKey` (Carbon) não exige Accessibility nem Input Monitoring.
- **Identidade visual "Tactile Telemetry"** (`design-philosophy.md`, `TactilePalette`): ver §7.
- **Ponto único de disparo.** O anel aciona via `SwitchRegistry.triggerSwitch(withID:)`, nunca `switch.trigger()` direto, para manter contador e telemetria coerentes com o popover.
- **Dois pipelines de build.** `swift build` e o fallback `swiftc` de `scripts/build-app.sh` (modo CommandLineTools). Os dois precisam compilar.
- **Testes sem XCTest no CommandLineTools.** O runner oficial é `scripts/run-tests.sh` (`precondition`). Testes XCTest ficam para quem usa Xcode.

## 4. Interação

### 4.1 Invocação

- Atalho padrão: **⌃⌥Space**, configurável.
- **Segurar** o atalho: anel abre no cursor; mover escolhe; **soltar** aciona a fatia em foco.
- **Toque rápido** (pressionar e soltar em menos de 250 ms sem foco): o anel fica **fixo** aberto. Clique numa fatia ou tecla 1–8 aciona; Esc ou clique fora fecha.
- O anel aparece com o último estado conhecido de cada switch e atualiza em seguida (`refreshState()` assíncrono). Meta: visível em até 100 ms.

### 4.2 Seleção

- Seleção pelo **ângulo** do cursor relativo ao centro. Dentro da zona morta (núcleo), nada fica em foco.
- Teclas **1–8** selecionam a fatia correspondente; **setas** giram o foco; **Enter** aciona; **Esc** cancela sempre.
- A fatia em foco avança 8 pt para fora, ganha contorno no acento do domínio e uma agulha liga o núcleo a ela.

### 4.3 Disparo e segurança

- Soltar com fatia em foco: aciona.
- Soltar na zona morta, sem ter movido, ou em menos de **150 ms** desde a abertura: **cancela**.
- Switches destrutivos (domínio `SEC` marcado como destrutivo, ex.: ejetar, limpar): exigem **parar ~300 ms** sobre a fatia; um arco de progresso mostra o "armando". Soltar antes de armar cancela.
- Um switch em `busy` ignora novo disparo.
- `unsupported`: fatia esmaecida, não aciona. `permissionRequired`: soltar abre a URL de ajustes.

### 4.3.1 Itens com várias escolhas (sub-anel)

Alguns switches agem sobre um alvo escolhido numa lista. Hoje só o `SW.17 BT AUDIO LINK`, que conecta ou desconecta o dispositivo Bluetooth preferido. O `SW.24 EJECT DISKS` ejeta todos os volumes e não tem escolha.

- A fatia ganha uma marca **▸** na borda. Soltar sobre ela age no **preferido**, como antes.
- **Abrir o leque:** empurrar o cursor além da borda da fatia (raio ≥ 133 pt), ou parar **400 ms** sobre ela, ou `Tab` no modo fixo.
- **Leque:** até **8** escolhas em arco por fora da fatia, 21° cada, centrado no ângulo dela, na ordem da lista do popover (conectados, depois áudio, depois nome). Excedente aparece como `+N`, sem ação. O resto do anel fica com 32% de opacidade.
- **Escolher:** pelo ângulo, com o cursor além da borda; teclas `1`–`8` e setas no modo fixo. Voltar ao centro ou apontar outra fatia fecha o leque. `Esc` fecha só o leque e não deixa reabrir por tempo até o foco mudar.
- **Disparo:** `RingOutcome.fireChoice(switchID:choiceID:)` chama `SwitchRegistry.triggerRingChoice`, que reaproveita `toggleBluetoothDevice` (o escolhido vira o preferido) e conta o uso do switch.
- Novos switches com escolhas: implementar `SwitchRegistry.ringChoices(forSwitchID:)` e `triggerRingChoice`. O `TactileSwitchProtocol` não muda.

### 4.4 Núcleo (centro)

| Situação | Linha 1 | Linha 2 | Linha 3 |
|---|---|---|---|
| Sem foco | `06 PINNED` | `02/06` (ligados/total) | `ONLINE` |
| Foco, toggle desligado | `SW.xx` | título | `SOLTE · LIGAR` |
| Foco, toggle ligado | `SW.xx` | título | `SOLTE · DESLIGAR` |
| Foco, momentâneo | `SW.xx` | título | `SOLTE · RUN ▸` |
| Destrutivo armando | `SW.xx · SEC` | título | `SEGURE · ARMANDO` |
| Executando | `SW.xx` | título | status (`busy`) |
| Cancelar | `ESC` | `CANCELAR` | `SOLTE NO CENTRO` |

## 5. Ordem e posições: pinados primeiro

### 5.1 Grade fixa de 8 posições

O anel tem sempre **8 posições**, mesmo com menos pins. Posições vazias aparecem tracejadas com `+`. Assim, fixar ou remover um pin não desloca os outros.

Prioridade das posições (ângulo, 0° = leste, sentido horário):

| Rank | Posição | Ângulo |
|---|---|---|
| 1 | Norte (topo) | −90° |
| 2 | Leste | 0° |
| 3 | Sul | 90° |
| 4 | Oeste | 180° |
| 5 | Nordeste | −45° |
| 6 | Sudeste | 45° |
| 7 | Sudoeste | 135° |
| 8 | Noroeste | −135° |

As direções cardeais são as mais rápidas e precisas, por isso recebem os pins mais usados. A tecla numérica de cada fatia é o seu rank (1–8) e aparece na própria fatia.

### 5.2 Ordem por uso, estável

- O rank dos pins segue o **uso por switch** (mais usado = rank 1).
- A ordem **não muda sozinha durante o uso**. Recalcular tudo só acontece quando o usuário aciona "Reorder Ring by Usage" (clique direito no botão `RING` do rodapé).
- Adicionar ou remover um pin faz um **ajuste mínimo**: quem saiu libera a posição (ela fica vazia), quem entrou ocupa a primeira posição livre por rank. Os demais não se movem.
- A grade é persistida (`studio.tactile.TactileBar.ring.slots`), então também não muda entre execuções do app.
- Desempate: ordem em que o switch foi fixado.
- Sem histórico de uso (primeira execução): ordem dos pins padrão.
- Mais de 8 pins: entram os 8 de maior rank; o núcleo mostra `+N` na linha 1.

### 5.3 Mudanças de dados no `SwitchRegistry`

1. **Uso por switch.** Novo dicionário `[String: Int]` em `UserDefaults` (`studio.tactile.TactileBar.switchTriggerCounts`), incrementado dentro de `triggerSwitch(withID:)`. O `totalTriggerCount` continua como está.
2. **Pins ordenados.** `pinnedSwitchIDs` hoje é `Set` e é gravado ordenado alfabeticamente. Passa a existir uma lista ordenada `pinnedOrder: [String]` (mesma chave de armazenamento, já é array). Compatibilidade: o array salvo atual é lido como ordem inicial. A API pública existente (`isPinned`, `togglePin`, `restoreDefaultPins`, `pinnedSwitchIDs`) continua funcionando.
3. **Ordem do anel.** Nova propriedade calculada pura `ringOrder` (ou função em `RingOrdering`) que aplica §5.2. Cacheada e invalidada só nos gatilhos de §5.2.

## 6. Arquitetura

A lógica pura (`RingGeometry`, `RingOrdering`, `RingSession`, `RingPreferences`) fica em `TactileCore/Ring/`, sem AppKit, para ser testada pelo `run-tests.sh` atual. Novo target `TactileRing` (biblioteca), dependendo de `TactileCore` e `TactileUI`, com atalho, painel, desenho e controlador. `TactileBarApp` passa a depender dele. Os textos do anel seguem o idioma da interface do app (inglês: `RELEASE · ON`, `HOLD · ARMING`).

| Componente | Camada | Responsabilidade |
|---|---|---|
| `RingGeometry` | lógica pura | Ângulo e distância → posição (0–7) ou zona morta. Tabela de §5.1. Sem AppKit. |
| `RingOrdering` | lógica pura | Pins + contagens + ordem de fixação → lista de até 8 IDs por rank (§5.2). |
| `RingSession` | estado (`@Observable`, `@MainActor`) | Máquina de estados: fechado → aberto(segurando/fixo) → armando → executando → fechado. Regras de 150 ms, 250 ms, 300 ms e cancelamento. Relógio injetável para testes. |
| `RingHotKey` | sistema | `RegisterEventHotKey` (Carbon), eventos de pressionar/soltar. |
| `RingPanel` | UI | `NSPanel` `.nonactivatingPanel`, sem borda, nível acima das janelas, não rouba foco, posicionado e ajustado para caber na tela do cursor. |
| `RingView` | UI | Desenho SwiftUI `Canvas` (§7). |
| `RingController` | composição | Liga `RingHotKey`, `RingSession`, `RingPanel` e `SwitchRegistry`; monitora mouse só enquanto aberto. |

Seguimento do mouse enquanto aberto: `NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved)` (não precisa de Accessibility para movimento) ou leitura de `NSEvent.mouseLocation` a 60 Hz, apenas com o anel aberto.

## 7. Visual (identidade Tactile Telemetry)

- Base no mostrador concêntrico existente (`ConcentricTelemetryDialCanvasView`): fundo `obsidianBackground`, aro `borderSteel`, anéis de calibragem `gridLine`, retícula `hairlineSubtle`, marcas menores a cada 5°, maiores nas divisões de fatia, pontos nos 4 cardeais.
- Fatias na cor do domínio (`TactilePalette.accentColor(for:)`):
  - desligado: `graphitePanel` com contorno `gridLine`, ícone em `silverMuted`;
  - ligado: acento a 15% + contorno acento 60% + **LED** na borda;
  - em foco: acento a 30%, contorno cheio, avanço de 8 pt, agulha;
  - executando: contorno tracejado pulsando;
  - armando: arco de progresso externo.
- Ícones: **`TactileVectorIconView`** existentes (não SF Symbols genéricos), em bezel circular.
- Rótulos externos: **título + status apenas** (sem `SW.xx`, coerente com o card "No API Noise"). Título em caixa-alta sans bold; status em mono.
- Núcleo: `graphitePanel` com aro no acento da fatia em foco (âmbar sem foco); zona morta marcada por círculo pontilhado.
- Sem Liquid Glass (suporte a macOS 14). Sombra suave do painel.

## 8. Acessibilidade

- Cor nunca é o único sinal: LED + preenchimento para "ligado"; avanço + contorno para "foco".
- Teclado completo (§4.2).
- VoiceOver: anunciar "Anel aberto, N itens" e "título, status, ação" do item em foco.
- **Reduzir movimento**: sem avanço animado; foco apenas por contorno.
- Texto pequeno só em `ivoryText` ou `silverMuted` (não `slateDim`) para manter contraste.

## 9. Configuração

Chaves em `UserDefaults`, prefixo `studio.tactile.TactileBar.ring.`:

| Chave | Tipo | Padrão |
|---|---|---|
| `enabled` | Bool | `false` |
| `hotKey` | código de tecla + modificadores | ⌃⌥Space |
| `holdThresholdMs` (toque rápido) | Int | 250 |
| `minOpenMs` (cancelar por soltar rápido) | Int | 150 |
| `armDwellMs` (destrutivos) | Int | 300 |

UI nas configurações: ativar, gravar atalho, "Reordenar por uso" e prévia da ordem atual.

**Descoberta:** dica discreta no popover ("Anel: segure ⌃⌥Space"), exibida enquanto o anel nunca foi usado.

## 10. Estrutura de arquivos

```
Sources/TactileCore/Ring/
  RingGeometry.swift
  RingOrdering.swift
  RingSession.swift
  RingPreferences.swift
Sources/TactileRing/
  RingHotKeyCenter.swift
  RingPanel.swift
  RingView.swift
  RingController.swift
Tests/TactileCoreTests/
  RingLogicTests.swift
```

Mudanças em arquivos existentes:

- `Package.swift`: target `TactileRing`, dependência em `TactileBarApp`, `testTarget`, `linkedFramework("Carbon")`.
- `scripts/build-app.sh`: compilar `TactileRing` no fallback `swiftc` depois de `TactileUI` e incluir `libTactileRing.a` no link final.
- `scripts/run-tests.sh`: verificações de geometria, ordenação e sessão no runner.
- `SwitchRegistry.swift`: §5.3 (aditivo, API existente preservada).
- `TactileBarApp.swift`: criar o `RingController` com o `registry`; iniciar se `enabled`.
- `MainPopoverView.swift` / `SupportAndAboutSheet.swift`: dica de descoberta e seção de configuração.
- `README.md`: seção do anel.

## 11. Testes

Lógica pura, rodando no `run-tests.sh` e em XCTest:

- `RingGeometry`: limites entre fatias, zona morta, as 8 posições, vetor nulo.
- `RingOrdering`: ordem por uso; desempate por ordem de fixação; sem histórico; mais de 8 pins; estabilidade (contagens mudam e a ordem não muda sem gatilho).
- `RingSession` (relógio injetado): segurar → mover → soltar aciona; soltar < 150 ms cancela; toque rápido fixa; zona morta cancela; Esc cancela; destrutivo só arma após 300 ms; `busy` ignora; `unsupported` não aciona.
- `SwitchRegistry`: contagem por switch incrementa em `triggerSwitch`; leitura do array antigo de pins preserva os pins.
- Regressão: os 5 testes atuais do `run-tests.sh` continuam passando.

Aceitação manual:

1. Com o anel desligado, o app se comporta exatamente como a v1.3.1.
2. Atalho abre o anel no cursor em qualquer app, em vários monitores e perto das bordas.
3. O app em foco não perde o foco nem recebe o atalho.
4. Ordem do anel segue o uso e não muda entre aberturas sem gatilho.
5. Soltar sobre uma fatia aciona o switch certo; o estado no anel e no popover coincide.
6. Destrutivo não dispara sem o arco completar.
7. Nenhum custo de CPU perceptível com o anel fechado.

## 12. Riscos

| Risco | Mitigação |
|---|---|
| Atalho em conflito com outro app | Configurável; aviso se `RegisterEventHotKey` falhar. |
| Disparo acidental | Regras de 150 ms, zona morta, armar 300 ms para destrutivos. |
| Mudança de dados dos pins quebrar instalações atuais | Mesma chave e formato (array); teste de compatibilidade. |
| Fallback do `build-app.sh` esquecer o módulo | Item explícito em §10; validar os dois pipelines. |
| Painel roubar foco | `NSPanel` `.nonactivatingPanel`, `canBecomeKey = false` no modo segurando. |

## 13. Plano de entrega

1. `RingGeometry` e `RingOrdering` com testes.
2. Contagem por switch e pins ordenados no `SwitchRegistry`, com testes de compatibilidade.
3. `RingSession` com testes.
4. `RingView` e `RingPanel` com dados simulados.
5. `RingHotKey` e `RingController` ligados ao registry.
6. Configurações, dica de descoberta e README.
7. `Package.swift` e scripts; validar `swift build`, `build-app.sh` e `run-tests.sh`.
