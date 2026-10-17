<div align="center">

# TactileBar

**Precision Menu Bar Telemetry & Hardware-Inspired Command Deck for macOS**  
*Instrumento de Telemetria e Deck de Comando Tátil para a Barra de Menus do macOS*

[![Version](https://img.shields.io/badge/Version-1.2.0-F59E0B?style=flat-square)](https://github.com/tr0drigues/TactileBar/releases/latest)
[![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-0B0C0E?style=flat-square&logo=apple&logoColor=F4F4F0)](https://github.com/tr0drigues/TactileBar/releases)
[![Swift](https://img.shields.io/badge/Swift-5.10%20%7C%206.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-10B981?style=flat-square)](Package.swift)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-F59E0B?style=flat-square)](LICENSE)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-EA4AAA?style=flat-square&logo=githubsponsors)](https://github.com/sponsors/tr0drigues)

[**🇺🇸 English**](#-english) · [**📖 User Manual**](#-user-manual) · [**🇧🇷 Português (Brasil)**](#-português-brasil) · [**📘 Manual de Utilização**](#-manual-de-utilização) · [**⬇️ Download (.dmg)**](https://github.com/tr0drigues/TactileBar/releases/latest)

</div>

![Tactile Telemetry Atlas](tactile-telemetry-canvas.png)

---

## 🇺🇸 English

### Stop digging through three levels of System Settings for daily macOS actions.

Developers, designers, and power users toggle the same system states dozens of times a day: keeping the Mac awake during a long build, switching Bluetooth headphones between calls, hiding desktop icons before sharing a screen, muting the microphone, inspecting external disk capacity, or purging gigabytes of Xcode `DerivedData`.

**TactileBar** replaces scattered system menus with a single, zero-scroll **Tactile Telemetry Instrument** anchored in your macOS Menu Bar. Inspired by Dieter Rams industrial hardware, Teenage Engineering field consoles, and horological chronographs, every switch and gauge is rendered in real time using native `SwiftUI Canvas` vector schematics and direct macOS kernel/system frameworks—with **zero third-party dependencies**.

---

### Why TactileBar?

* **Symmetric 3-Deck Telemetry Instrument**:
  * **Left Deck — Direct Bluetooth RF Link (`IOBluetooth`) & Live CPU/RAM Gauges**: Cycle through all paired Bluetooth headphones, speakers, and controllers (`EDIFIER`, `JBL`, `AirPods`, `DualSense`, keyboards, mice) via a contained stepper or expandable vertical list, and connect or disconnect with a single click. Below it, live Mach kernel gauges track **`CPU.LOAD`** (`USER / SYS %`) and **`MEM.RAM`** (`Used / Total GB`).
  * **Centerpiece — Triple Concentric Rotary Telemetry Dial**: A 26-sector radial chronograph that maps active system switches on its outer bezel and three concentric hardware telemetry rings inside: **CPU Load (Amber)**, **RAM Pressure (Emerald)**, and **Storage Saturation (Cyan)**. Click the core to cycle through mounted disks.
  * **Right Deck — Multi-Volume Storage (`DiskArbitration`) & Power/Thermal Readouts**: Inspect free space and usage ratios across internal and external drives (`Macintosh HD`, `DADOS`, SD cards), reveal volumes in Finder, or eject individual removable disks safely, alongside live **`PWR.SOURCE`** (`IOKit` battery/AC state) and **`THERMAL`** (`ProcessInfo` nominal/elevated state) telemetry.
* **26 Hardware-Inspired Switches Across 5 Domains**:
  * Every switch features a bespoke 36pt vector schematic inside a 12-tick horological bezel—never generic placeholder icons.
* **Zero-Scroll Ergonomics, Isolated Subviews & Zero Idle CPU (`0.0%`)**:
  * Engineered around a strict `540×576pt` vertical budget so all 5 domain tabs (`PWR`, `OPT`, `WKS`, `SIG`, `SEC`) display their complete switch matrix without a scrollbar.
  * Built with isolated `@Observable` subviews, cached `NSImage` menu bar icons, zero `GeometryReader` layout passes, and parallelized `TaskGroup` state synchronization. Mach kernel telemetry (`host_processor_info`, `host_statistics64`) is sampled **only while the popover is open on screen**.
* **100% Native User-Space Execution & VoiceOver Accessible**:
  * Built directly on `Darwin.Mach`, `IOKit`, `CoreAudio`, `CoreGraphics`, `IOBluetooth`, `DiskArbitration`, `AppKit`, and `CoreImage`. Full VoiceOver labels, values, and keyboard navigation (`⌘1`–`⌘5`, `⌘0`, `⌘R`).

![Concentric Telemetry Deck](telemetry-deck-preview.png)

---

### 📖 User Manual

#### 1. Launching & Opening the Instrument
* When launched, **TactileBar** runs as a lightweight menu bar accessory (`LSUIElement`) without cluttering your Dock or `⌘Tab` switcher.
* Click the **radial gauge icon** in the macOS Menu Bar to open the instrument popover. The menu bar icon dynamically reflects the number of active switches.

#### 2. Header Bar Controls
From left to right across the top header bar:
1. **Inline Telemetry Filter (`FILTER (SW.01, AUDIO, DARK)...`)**:
   * Type any switch code (`SW.01`, `SW.25`), keyword (`DARK`, `MUTE`, `XCODE`, `TRASH`), or native subsystem (`IOKit`, `CoreAudio`, `Finder`) to filter the switch grid instantaneously across all domains.
   * Click the **`×`** button inside the search field to clear the filter.
2. **`DIAL: ON / OFF` Toggle**:
   * Collapses or expands the 3-column Concentric Telemetry Deck if you prefer to view only the switch grid.
3. **`SW XX/26` Status Readout**:
   * Displays how many continuous switches are currently engaged (`ON`) out of the 26 total switches.
4. **`↻` Refresh Button (`⌘R`)**:
   * Triggers a parallelized `TaskGroup` synchronization across all 26 switches, mounted disk volumes, paired Bluetooth devices, and Mach hardware gauges.

#### 3. Domain Navigation & Keyboard Shortcuts
Switch between the 5 functional hardware domains using either mouse clicks or native keyboard shortcuts:

| Shortcut | Tab Badge | Domain Title | Switch Count | Primary Accent |
| :---: | :---: | :--- | :---: | :--- |
| **`⌘1`** | `PWR` | `M.01 // POWER & SLEEP` | 5 | Tungsten Amber (`#F59E0B`) |
| **`⌘2`** | `OPT` | `M.02 // OPTICS & LUMINANCE` | 4 | Warm Ivory (`#F4F4F0`) |
| **`⌘3`** | `WKS` | `M.03 // SPATIAL WORKSPACE` | 6 | Oscilloscope Cyan (`#38BDF8`) |
| **`⌘4`** | `SIG` | `M.04 // ACOUSTIC & RF SIGNAL` | 3 | Signal Emerald (`#10B981`) |
| **`⌘5`** | `SEC` | `M.05 // SECURITY & PURGE` | 8 | International Orange (`#FF5722`) |
| **`⌘0`** | `ALL` | All 26 Switches (Scrollable Atlas) | 26 | Neutral Titanium |
| **`⌘R`** | `↻` | Synchronize All Telemetry & Switches | — | Oscilloscope Cyan |

Each domain tab displays a live **`Active/Total`** counter (for example, `PWR 1/5`).

#### 4. Operating the 3-Column Telemetry Deck

* **Left Column — Bluetooth RF Deck & CPU/RAM Gauges**:
  * **Stepping Devices**: Click **`[ ◀ ]`** or **`[ ▶ ]`** to cycle through all paired Bluetooth devices (`01/03`).
  * **Dropdown List**: Click the center selector button (`01/03 DEVICE ▾`) to expand a scrollable list of all paired devices with live `ON` / `OFF` indicators. Clicking any device selects it and closes the list.
  * **1-Click Connect / Disconnect**: Click **`CONNECT`** or **`DISCONNECT`** on the active device card. Your selected device is saved in `UserDefaults` and linked with switch **`SW.17`** (`Bluetooth Audio Link`).
  * **CPU & RAM Telemetry**: Below the Bluetooth card, two live gauges display **`CPU.LOAD`** (total percentage + `USR` and `SYS` breakdown via `host_processor_info`) and **`MEM.RAM`** (used percentage + `Used / Total GB` via `host_statistics64`).
* **Center Column — Triple Concentric Rotary Dial**:
  * **Outer 26-Sector Ring**: Each sector corresponds to `SW.01` through `SW.26`. Engaging any switch illuminates its corresponding sector and projects an internal radial beam toward the center.
  * **3 Concentric Inner Rings**:
    * **Outer Ring (Amber)**: CPU Load (`0–100%`).
    * **Middle Ring (Emerald)**: RAM Usage (`0–100%`).
    * **Inner Ring (Cyan / Emerald)**: Active Storage Volume saturation (`0–100%`). Turns crimson if disk usage exceeds `88%`.
  * **Interactive Core**: Displays live `C:XX R:YY` (CPU/RAM %), disk usage percentage, and volume badge (`INT.01` for internal, `EXT.02` for removable). **Click the center of the dial** to cycle to the next mounted disk volume.
* **Right Column — Storage Volumes Deck & Power/Thermal Gauges**:
  * **Stepping & Selecting Volumes**: Use **`[ ◀ ]`** / **`[ ▶ ]`** or click **`01/02 VOLUME ▾`** to inspect any mounted APFS, HFS+, ExFAT, or network drive.
  * **Finder & Safe Eject**: Click **`OPEN`** to reveal the selected volume in Finder. If the volume is removable (`EXT`), an **`EJECT ⏏`** button appears so you can unmount that specific drive safely.
  * **Power & Thermal Telemetry**: Below the volume card, two live gauges display **`PWR.SOURCE`** (`AC.LINE` or battery percentage/charging status via `IOKit.ps`) and **`THERMAL`** (`NOMINAL`, `FAIR`, `SERIOUS`, or `CRITICAL` via `ProcessInfo.thermalState`).

#### 5. Continuous Toggles vs. Momentary Actions
TactileBar distinguishes between two physical switch behaviors on the right side of each card:
1. **Continuous Toggles (Sliding Pill Switch)**:
   * Maintain an active `ON` or `OFF` state (e.g., `SW.01 Keep Awake`, `SW.06 Dark Mode`, `SW.10 Hide Desktop Icons`, `SW.11 Show Hidden Files`, `SW.12 Auto-Hide Dock`, `SW.16 Mute Microphone`, `SW.17 Bluetooth Audio Link`).
   * Active switches illuminate their vector schematic, left border bar, and radial sector in the dial.
2. **Momentary Pulse Triggers (`RUN ▶` Capsule)**:
   * Execute an immediate one-shot operation (e.g., `SW.02 Display Sleep`, `SW.03 Screen Saver`, `SW.21 Lock Workstation`, `SW.22 Empty Trash`, `SW.23 Purge Pasteboard`, `SW.24 Eject External Disks`, `SW.25 Purge Xcode Cache`).

> **Safety Escape Hatch (`SW.19` & `SW.20`)**:  
> When activating **`SW.19 Screen Clean Shield`** (blackout overlay for cleaning your display) or **`SW.20 Lock Keyboard`** (suppresses physical keystrokes while cleaning the keyboard), you can press **`ESC` twice (`ESC + ESC`)** at any moment to immediately disengage the lock.

#### 6. macOS Permissions Guide
TactileBar operates strictly in user space and requests permissions only when a switch requires them:
* **Automation (`System Events` / `Finder` / `Music` / `Spotify`)**: Used by `SW.06 Dark Mode`, `SW.10–SW.12` (Finder/Dock), `SW.18 Media Transport`, and `SW.22 Empty Trash`.
* **Accessibility (`CGEventTap`)**: Required only if you use `SW.20 Lock Keyboard` to intercept physical keystrokes while cleaning your keyboard.
* **Bluetooth (`IOBluetooth`)**: Used by the Left Telemetry Deck and `SW.17` to list and connect paired Bluetooth devices.
* If a permission has not been granted yet, the switch card displays **`GRANT PERMISSION`** and clicking it opens the exact pane in **System Settings → Privacy & Security**.

---

### Complete 26-Switch Catalog

| Domain | Code | Switches (`SW.01` – `SW.26`) | Native macOS Mechanism |
| :--- | :--- | :--- | :--- |
| **Power & Sleep** | `M.01 PWR` | `SW.01` Keep Awake · `SW.02` Display Sleep · `SW.03` Screen Saver · `SW.04` Low Power Mode · `SW.05` High Power Mode | `IOPMAssertionCreateWithName`, `io_registry_entry`, `/usr/bin/pmset`, `ScreenSaverEngine` |
| **Optics & Display** | `M.02 OPT` | `SW.06` Dark Mode · `SW.07` Night Shift · `SW.08` True Tone · `SW.09` Retina Scaling | `System Events`, `CoreGraphics` (`CGMainDisplayID`), Displays URI |
| **Workspace & Dock** | `M.03 WKS` | `SW.10` Hide Desktop Icons · `SW.11` Show Hidden Files · `SW.12` Auto-Hide Dock · `SW.13` Isolate Active Window · `SW.14` Stage Manager · `SW.15` Desktop Widgets | `com.apple.finder`, `com.apple.dock`, `com.apple.WindowManager`, `NSWorkspace` |
| **Acoustic & RF** | `M.04 SIG` | `SW.16` Mute Microphone · `SW.17` Bluetooth Audio Link · `SW.18` Media Transport | `CoreAudio` (`kAudioHardwarePropertyDefaultInputDevice`), `IOBluetooth`, `Music` / `Spotify` |
| **Security & Purge** | `M.05 SEC` | `SW.19` Screen Clean Shield · `SW.20` Lock Keyboard · `SW.21` Lock Workstation · `SW.22` Empty Trash · `SW.23` Purge Pasteboard · `SW.24` Eject External Disks · `SW.25` Purge Xcode Cache · `SW.26` Focus / DND | `NSWindow.Level.screenSaver`, `NSEvent`, `NSPasteboard`, `FileManager`, `DiskArbitration` |

---

### Quick Start & Installation

#### Option 1 — Download Prebuilt Release (`.dmg` / `.zip`)
1. Download `TactileBar-macOS.dmg` from the [**Releases**](https://github.com/tr0drigues/TactileBar/releases/latest) page.
2. Move `TactileBar.app` to `/Applications`.
3. Because the binary uses free *Ad-Hoc* signing, clear the macOS quarantine attribute before the first launch:
   ```bash
   xattr -cr /Applications/TactileBar.app
   open /Applications/TactileBar.app
   ```

#### Option 2 — Build from Source
Requirements: **macOS 14.0 (Sonoma)+** and **Xcode 15.4+ / Swift 5.10+**.

```bash
git clone https://github.com/tr0drigues/TactileBar.git
cd TactileBar

# Run the unit test suite
swift test

# Compile Release binary, generate AppIcon.icns, and assemble Ad-Hoc signed bundle
chmod +x scripts/build-app.sh
./scripts/build-app.sh

# Launch in the macOS Menu Bar
open TactileBar.app
```

---

## 🇧🇷 Português (Brasil)

### Pare de navegar por três submenus nos Ajustes do Sistema para tarefas que você repete dezenas de vezes por dia.

Quem desenvolve software, edita mídia ou trabalha intensamente no Mac repete os mesmos comandos todos os dias: impedir que o Mac durma durante um build longo, conectar ou desconectar um fone Bluetooth entre reuniões, ocultar ícones da Mesa antes de compartilhar a tela, mutar o microfone, inspecionar o espaço livre de um SSD externo ou limpar gigabytes do `DerivedData` do Xcode.

O **TactileBar** substitui menus espalhados por um **Instrumento de Telemetria Tátil** único na barra de menus do macOS. Inspirado no design industrial de Dieter Rams (Braun), em consoles de campo da Teenage Engineering e na relojoaria de precisão, cada interruptor e medidor é desenhado em tempo real via `SwiftUI Canvas` vetorial e opera diretamente sobre frameworks nativos e chamadas Mach do macOS — **sem nenhuma dependência externa**.

---

### Diferenciais do TactileBar

* **Deck de Telemetria Simétrico de 3 Colunas**:
  * **Deck Esquerdo — Controle Direto Bluetooth RF (`IOBluetooth`) + Medidores de CPU e RAM**: Navegue por todos os seus fones, caixas de som e controles pareados (`EDIFIER`, `JBL`, `AirPods`, `DualSense`, teclados, mouses) através do seletor `[ ◀ ] 01/03 [ ▶ ]` ou da lista vertical expansível, conectando e desconectando com **1 clique**. Abaixo, medidores nativos do kernel Mach exibem **`CPU.LOAD`** (`USER / SYS %`) e **`MEM.RAM`** (`GB Usados / Total`).
  * **Centro — Mostrador Rotativo Concêntrico Triplo (`Triple Concentric Telemetry Dial`)**: Cronógrafo radial de 26 setores que mapeia os módulos ativos no anel externo e três anéis concêntricos de telemetria de hardware no interior: **Carga de CPU (Âmbar)**, **Pressão de Memória RAM (Esmeralda)** e **Ocupação do Disco (Ciano)**. Clique no núcleo para alternar rapidamente entre seus discos.
  * **Deck Direito — Telemetria Multi-Volume (`DiskArbitration`) + Energia e Estado Térmico**: Acompanhe espaço livre e ocupação de cada volume interno ou externo (`Macintosh HD`, `DADOS`, cartões SD), abra no Finder com `OPEN` ou ejete discos removíveis individualmente com `EJECT ⏏`, além dos indicadores de fonte de energia **`PWR.SOURCE`** (`IOKit`) e **`THERMAL`** (`ProcessInfo`).
* **26 Módulos com Esquemáticos Vetoriais Exclusivos**:
  * Cada módulo (`SW.01` a `SW.26`) possui uma gravura técnica vetorial própria dentro de uma moldura horológica de 12 marcações.
* **Fluidez Zero-Rolagem, Subviews Isoladas e `0.0%` de CPU em Segundo Plano**:
  * Orçamento vertical calibrado em `540×576pt` para que todas as 5 abas de domínio (`PWR`, `OPT`, `WKS`, `SIG`, `SEC`) exibam todos os seus interruptores sem barra de rolagem.
  * Arquitetura com subviews `@Observable` isoladas, cache de `NSImage` na barra de menus, zero `GeometryReader` e sincronização paralela via `TaskGroup`. A telemetria do kernel Mach (`host_processor_info` e `host_statistics64`) é amostrada **apenas enquanto o popover está aberto na tela**.
* **Execução 100% Nativa em User-Space e Acessibilidade VoiceOver**:
  * Construído diretamente sobre `Darwin.Mach`, `IOKit`, `CoreAudio`, `CoreGraphics`, `IOBluetooth`, `DiskArbitration`, `AppKit` e `CoreImage`, com suporte completo a VoiceOver e atalhos de teclado (`⌘1`–`⌘5`, `⌘0`, `⌘R`).

---

### 📘 Manual de Utilização

#### 1. Abertura e Ícone na Barra de Menus
* Ao ser iniciado, o **TactileBar** opera como um utilitário de barra de menus (`LSUIElement`), sem ocupar espaço no Dock ou no alternador `⌘Tab`.
* Clique no **ícone radial de telemetria** na barra de menus do macOS para abrir o painel. O ícone da barra de menus atualiza automaticamente seu arco e contador conforme interruptores são ativados ou desativados.

#### 2. Barra Superior de Comando
Da esquerda para a direita no cabeçalho superior:
1. **Filtro de Busca Instantânea (`FILTER (SW.01, AUDIO, DARK)...`)**:
   * Digite o código do módulo (`SW.01`, `SW.25`), nome (`DARK`, `MUTE`, `XCODE`, `TRASH`) ou subsistema nativo (`IOKit`, `CoreAudio`, `Finder`) para filtrar instantaneamente os 26 módulos.
   * Clique no botão **`×`** dentro do campo para limpar a busca.
2. **Botão `DIAL: ON / OFF`**:
   * Recolhe ou exibe o Deck de Telemetria de 3 Colunas caso você deseje visualizar apenas a grade de interruptores.
3. **Indicador `SW XX/26`**:
   * Mostra quantos interruptores contínuos estão ativos (`ON`) naquele momento.
4. **Botão de Sincronização `↻` (`⌘R`)**:
   * Dispara uma varredura paralela (`TaskGroup`) atualizando o estado dos 26 interruptores, volumes montados, dispositivos Bluetooth pareados e sensores Mach de hardware.

#### 3. Navegação por Domínios e Atalhos de Teclado
Você pode alternar entre os 5 domínios funcionais clicando nas abas ou usando atalhos nativos de teclado:

| Atalho | Aba | Domínio Funcional | Qtd. de Módulos | Cor de Destaque |
| :---: | :---: | :--- | :---: | :--- |
| **`⌘1`** | `PWR` | `M.01 // POWER & SLEEP` (Energia e Repouso) | 5 | Âmbar Tungstênio (`#F59E0B`) |
| **`⌘2`** | `OPT` | `M.02 // OPTICS & LUMINANCE` (Óptica e Tela) | 4 | Marfim Quente (`#F4F4F0`) |
| **`⌘3`** | `WKS` | `M.03 // SPATIAL WORKSPACE` (Mesa, Finder e Dock) | 6 | Ciano Osciloscópio (`#38BDF8`) |
| **`⌘4`** | `SIG` | `M.04 // ACOUSTIC & RF SIGNAL` (Áudio e Bluetooth) | 3 | Verde Esmeralda (`#10B981`) |
| **`⌘5`** | `SEC` | `M.05 // SECURITY & PURGE` (Segurança e Limpeza) | 8 | Laranja Internacional (`#FF5722`) |
| **`⌘0`** | `ALL` | Visão Geral com todos os 26 Módulos | 26 | Titânio Neutro |
| **`⌘R`** | `↻` | Sincronizar Telemetria e Interruptores | — | Ciano Osciloscópio |

Cada aba exibe em tempo real o contador **`Ativos/Total`** do respectivo domínio (ex.: `PWR 1/5`).

#### 4. Operando o Deck de Telemetria de 3 Colunas

* **Coluna Esquerda — Deck Bluetooth RF e Medidores de CPU/RAM**:
  * **Alternar Dispositivos**: Use os botões **`[ ◀ ]`** e **`[ ▶ ]`** para percorrer todos os dispositivos Bluetooth pareados no macOS (`01/03`).
  * **Lista Vertical Expansível**: Clique no seletor central (`01/03 NOME ▾`) para abrir a lista completa de dispositivos pareados com indicadores `ON` / `OFF`. Clique em qualquer item para selecioná-lo.
  * **Conectar / Desconectar com 1 Clique**: Clique em **`CONNECT`** ou **`DISCONNECT`** diretamente no cartão. O dispositivo escolhido fica salvo como seu dispositivo preferido e sincronizado com o interruptor **`SW.17`** (`Bluetooth Audio Link`).
  * **Medidores de CPU e RAM**: Abaixo do cartão Bluetooth, dois instrumentos exibem em tempo real **`CPU.LOAD`** (percentual total + divisão `USR` e `SYS` via `host_processor_info`) e **`MEM.RAM`** (percentual ocupado + `GB Usados / Total` via `host_statistics64`).
* **Coluna Central — Mostrador Rotativo Concêntrico Triplo**:
  * **Anel Externo de 26 Setores**: Cada setor radial representa um módulo de `SW.01` a `SW.26`. Quando um módulo está ativo, seu setor acende na cor do domínio e projeta um feixe radial até o núcleo.
  * **3 Anéis Concêntricos Internos**:
    * **Anel Externo (Âmbar)**: Carga total de CPU (`0–100%`).
    * **Anel Intermediário (Esmeralda)**: Saturação de Memória RAM (`0–100%`).
    * **Anel Interno (Ciano / Esmeralda)**: Ocupação do Volume de Armazenamento selecionado (`0–100%`). Muda para vermelho carmesim se o disco ultrapassar `88%` de ocupação.
  * **Núcleo Interativo**: Exibe `C:XX R:YY` (CPU/RAM %), percentual usado do disco atual e o código do volume (`INT.01` para interno, `EXT.02` para externo). **Clique no centro do dial** para alternar entre os discos montados.
* **Coluna Direita — Deck de Armazenamento e Medidores de Energia/Temperatura**:
  * **Seleção de Volumes**: Use **`[ ◀ ]`** / **`[ ▶ ]`** ou clique em **`01/02 VOLUME ▾`** para inspecionar qualquer volume interno ou externo (`Macintosh HD`, `DADOS`, SSDs USB/Thunderbolt, cartões SD).
  * **Abrir no Finder e Ejeção Segura**: Clique em **`OPEN`** para revelar o volume no Finder. Para discos removíveis (`EXT`), o botão **`EJECT ⏏`** desmonta com segurança apenas o volume selecionado.
  * **Medidores de Energia e Estado Térmico**: Abaixo do cartão de disco, dois instrumentos exibem **`PWR.SOURCE`** (`AC.LINE` na tomada ou percentual/estado da bateria via `IOKit.ps`) e **`THERMAL`** (`NOMINAL`, `FAIR`, `SERIOUS` ou `CRITICAL` via `ProcessInfo.thermalState`).

#### 5. Interruptores Contínuos vs. Gatilhos Instantâneos
Cada cartão na grade possui um controle tátil à direita que identifica seu modo de operação:
1. **Interruptores Contínuos (Chave Seletora Deslizante)**:
   * Mantêm estado ligado (`ON`) ou desligado (`OFF`), como `SW.01 Keep Awake`, `SW.06 Dark Mode`, `SW.10 Hide Desktop Icons`, `SW.11 Show Hidden Files`, `SW.12 Auto-Hide Dock`, `SW.16 Mute Microphone` e `SW.17 Bluetooth Audio Link`.
   * Quando ativos, iluminam o esquemático vetorial, a barra lateral do cartão e o setor correspondente no dial radial.
2. **Gatilhos de Pulso Instantâneo (Cápsula `RUN ▶`)**:
   * Executam uma ação imediata e pontual, como `SW.02 Display Sleep`, `SW.03 Screen Saver`, `SW.21 Lock Workstation`, `SW.22 Empty Trash`, `SW.23 Purge Pasteboard`, `SW.24 Eject External Disks` e `SW.25 Purge Xcode Cache`.

> **Destravamento de Emergência (`SW.19` e `SW.20`)**:  
> Ao ativar o **`SW.19 Screen Clean Shield`** (tela preta para limpeza física do monitor) ou o **`SW.20 Lock Keyboard`** (bloqueio temporário das teclas para limpeza do teclado), basta pressionar **`ESC` duas vezes seguidas (`ESC + ESC`)** a qualquer momento para destravar imediatamente.

#### 6. Guia de Permissões do macOS
O TactileBar opera estritamente em *user-space* e solicita permissões do macOS apenas quando você aciona um módulo que depende delas:
* **Automação (`System Events` / `Finder` / `Music` / `Spotify`)**: Utilizada por `SW.06 Dark Mode`, `SW.10–SW.12` (Finder/Dock), `SW.18 Media Transport` e `SW.22 Empty Trash`.
* **Acessibilidade (`CGEventTap`)**: Necessária apenas para o módulo `SW.20 Lock Keyboard` interceptar as teclas físicas durante a limpeza do teclado.
* **Bluetooth (`IOBluetooth`)**: Utilizada pelo Deck Bluetooth e pelo módulo `SW.17` para listar e conectar dispositivos pareados.
* Caso alguma permissão ainda não tenha sido concedida, o cartão exibe **`GRANT PERMISSION`** e, ao ser clicado, abre diretamente a seção correspondente em **Ajustes do Sistema → Privacidade e Segurança**.

---

### Catálogo Completo dos 26 Módulos

| Domínio | Código | Módulos (`SW.01` – `SW.26`) | Mecanismo Nativo macOS |
| :--- | :--- | :--- | :--- |
| **Power & Sleep** | `M.01 PWR` | `SW.01` Keep Awake · `SW.02` Display Sleep · `SW.03` Screen Saver · `SW.04` Low Power Mode · `SW.05` High Power Mode | `IOPMAssertionCreateWithName`, `io_registry_entry`, `/usr/bin/pmset`, `ScreenSaverEngine` |
| **Optics & Display** | `M.02 OPT` | `SW.06` Dark Mode · `SW.07` Night Shift · `SW.08` True Tone · `SW.09` Retina Scaling | `System Events`, `CoreGraphics` (`CGMainDisplayID`), Displays URI |
| **Workspace & Dock** | `M.03 WKS` | `SW.10` Hide Desktop Icons · `SW.11` Show Hidden Files · `SW.12` Auto-Hide Dock · `SW.13` Isolate Active Window · `SW.14` Stage Manager · `SW.15` Desktop Widgets | `com.apple.finder`, `com.apple.dock`, `com.apple.WindowManager`, `NSWorkspace` |
| **Acoustic & RF** | `M.04 SIG` | `SW.16` Mute Microphone · `SW.17` Bluetooth Audio Link · `SW.18` Media Transport | `CoreAudio` (`kAudioHardwarePropertyDefaultInputDevice`), `IOBluetooth`, `Music` / `Spotify` |
| **Security & Purge** | `M.05 SEC` | `SW.19` Screen Clean Shield · `SW.20` Lock Keyboard · `SW.21` Lock Workstation · `SW.22` Empty Trash · `SW.23` Purge Pasteboard · `SW.24` Eject External Disks · `SW.25` Purge Xcode Cache · `SW.26` Focus / DND | `NSWindow.Level.screenSaver`, `NSEvent`, `NSPasteboard`, `FileManager`, `DiskArbitration` |

---

### Instalação Rápida e Compilação

#### Opção 1 — Baixar Versão Pronta (`.dmg` / `.zip`)
1. Baixe o `TactileBar-macOS.dmg` na página de [**Releases**](https://github.com/tr0drigues/TactileBar/releases/latest).
2. Arraste o `TactileBar.app` para `/Applications`.
3. Como o binário utiliza assinatura gratuita *Ad-Hoc*, remova o atributo de quarentena antes da primeira execução:
   ```bash
   xattr -cr /Applications/TactileBar.app
   open /Applications/TactileBar.app
   ```

#### Opção 2 — Compilar do Código-Fonte
Requisitos: **macOS 14.0 (Sonoma)+** e **Xcode 15.4+ / Swift 5.10+**.

```bash
git clone https://github.com/tr0drigues/TactileBar.git
cd TactileBar

# Executar a suíte de testes unitários
swift test

# Compilar em modo Release, gerar AppIcon.icns e montar o bundle TactileBar.app
chmod +x scripts/build-app.sh
./scripts/build-app.sh

# Iniciar o aplicativo na barra de menus
open TactileBar.app
```

---

## ☕ Support Craftsmanship / Apoie o Projeto

If **TactileBar** saves you time every day, consider supporting its development via **GitHub Sponsors**:  
Se o **TactileBar** economiza o seu tempo no dia a dia, considere apoiar a evolução do projeto via **GitHub Sponsors**:

* **GitHub Sponsors**: [https://github.com/sponsors/tr0drigues](https://github.com/sponsors/tr0drigues)

---

## 📄 License / Licença

Distributed under the **[GNU General Public License v3.0 (GPLv3)](LICENSE)** — free to use, study, and modify, ensuring that any derivative distribution remains open-source under the same license.  
Distribuído sob a licença **[GNU General Public License v3.0 (GPLv3)](LICENSE)** — livre para usar, estudar e modificar, garantindo que qualquer redistribuição ou derivado permaneça de código aberto sob a mesma licença.
