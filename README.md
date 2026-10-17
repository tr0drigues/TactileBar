<div align="center">

# TactileBar

**Precision Menu Bar Telemetry & Hardware-Inspired Command Deck for macOS**  
*Instrumento de Telemetria e Deck de Comando Tátil para a Barra de Menus do macOS*

[![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-0B0C0E?style=flat-square&logo=apple&logoColor=F4F4F0)](https://github.com/tr0drigues/TactileBar/releases)
[![Swift](https://img.shields.io/badge/Swift-5.10%20%7C%206.0-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-10B981?style=flat-square)](Package.swift)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-F59E0B?style=flat-square)](LICENSE)
[![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-EA4AAA?style=flat-square&logo=githubsponsors)](https://github.com/sponsors/tr0drigues)

[**English**](#-english) · [**Português (Brasil)**](#-português-brasil) · [**Download Latest Release (.dmg)**](https://github.com/tr0drigues/TactileBar/releases/latest)

</div>

![Tactile Telemetry Atlas](tactile-telemetry-canvas.png)

---

## 🇺🇸 English

### Stop digging through three levels of System Settings for daily macOS actions.

Developers, designers, and power users toggle the same system states dozens of times a day: keeping the Mac awake during a long build, switching Bluetooth headphones between calls, hiding desktop icons before sharing a screen, muting the microphone, inspecting external disk capacity, or purging gigabytes of Xcode `DerivedData`.

**TactileBar** replaces scattered system menus with a single, zero-scroll **Tactile Telemetry Instrument** anchored in your macOS Menu Bar. Inspired by Dieter Rams industrial hardware, Teenage Engineering field consoles, and horological chronographs, every switch is rendered in real time using native `SwiftUI Canvas` vector schematics and direct macOS frameworks—with **zero third-party dependencies**.

---

### Why TactileBar?

* **Symmetric 3-Deck Telemetry Instrument**:
  * **Left Deck — Direct Bluetooth RF Link (`IOBluetooth`) & Live CPU/RAM Gauges**: Cycle through all paired Bluetooth headphones, speakers, and controllers (`EDIFIER`, `JBL`, `AirPods`, `DualSense`, keyboards, mice) via a contained stepper or expandable vertical list, and connect or disconnect with a single click. Below it, live Mach kernel gauges track **`CPU.LOAD`** (`USER / SYS %`) and **`MEM.RAM`** (`Used / Total GB`).
  * **Centerpiece — Triple Concentric Rotary Telemetry Dial**: A 26-sector radial chronograph that maps active system switches on its outer bezel and three concentric hardware telemetry rings inside: **CPU Load (Amber)**, **RAM Pressure (Emerald)**, and **Storage Saturation (Cyan)**. Click the core to cycle through mounted disks.
  * **Right Deck — Multi-Volume Storage (`DiskArbitration`) & Power/Thermal Readouts**: Inspect free space and usage ratios across internal and external drives (`Macintosh HD`, `DADOS`, SD cards), reveal volumes in Finder, or eject individual removable disks safely, alongside live **`PWR.SOURCE`** (`IOKit` battery/AC state) and **`THERMAL`** (`ProcessInfo` nominal/elevated state) telemetry.
* **26 Hardware-Inspired Switches Across 5 Domains**:
  * Every switch features a bespoke 36pt vector schematic inside a 12-tick horological bezel—never generic placeholder icons.
* **Zero-Scroll Ergonomics & Zero Idle CPU (`0.0%`)**:
  * Engineered around a strict `540×576pt` vertical budget so all 5 domain tabs (`PWR`, `OPT`, `WKS`, `SIG`, `SEC`) display their complete switch matrix without a scrollbar. Mach kernel telemetry (`host_processor_info`, `host_statistics64`) is sampled only while the popover is open on screen.
* **100% Native User-Space Execution**:
  * Built directly on `Darwin.Mach`, `IOKit`, `CoreAudio`, `CoreGraphics`, `IOBluetooth`, `DiskArbitration`, `AppKit`, and `CoreImage`. No Electron, no background daemons, and no external Swift packages.

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

### Pare de navegar por três submenus nas Ajustes do Sistema para tarefas que você repete dezenas de vezes por dia.

Quem desenvolve software, edita mídia ou trabalha intensamente no Mac repete os mesmos comandos todos os dias: impedir que o Mac durma durante um build longo, conectar ou desconectar um fone Bluetooth entre reuniões, ocultar ícones da Mesa antes de compartilhar a tela, mutar o microfone, inspecionar o espaço livre de um SSD externo ou limpar gigabytes do `DerivedData` do Xcode.

O **TactileBar** substitui menus espalhados por um **Instrumento de Telemetria Tátil** único na barra de menus do macOS. Inspirado no design industrial de Dieter Rams (Braun), em consoles de campo da Teenage Engineering e na relojoaria de precisão, cada interruptor é desenhado em tempo real via `SwiftUI Canvas` vetorial e opera diretamente sobre frameworks nativos do macOS — **sem nenhuma dependência externa**.

---

### Diferenciais do TactileBar

* **Deck de Telemetria Simétrico de 3 Colunas**:
  * **Deck Esquerdo — Controle Direto Bluetooth RF (`IOBluetooth`) + Medidores de CPU e RAM**: Navegue por todos os seus fones, caixas de som e controles pareados (`EDIFIER`, `JBL`, `AirPods`, `DualSense`, teclados, mouses) através do seletor `[ ◀ ] 01/03 [ ▶ ]` ou da lista vertical expansível, conectando e desconectando com **1 clique**. Abaixo, medidores nativos do kernel Mach exibem **`CPU.LOAD`** (`USER / SYS %`) e **`MEM.RAM`** (`GB Usados / Total`).
  * **Centro — Mostrador Rotativo Concêntrico Triplo (`Triple Concentric Telemetry Dial`)**: Cronógrafo radial de 26 setores que mapeia os módulos ativos no anel externo e três anéis concêntricos de telemetria de hardware no interior: **Carga de CPU (Âmbar)**, **Pressão de Memória RAM (Esmeralda)** e **Ocupação do Disco (Ciano)**. Clique no núcleo para alternar rapidamente entre seus discos.
  * **Deck Direito — Telemetria Multi-Volume (`DiskArbitration`) + Energia e Estado Térmico**: Acompanhe espaço livre e ocupação de cada volume interno ou externo (`Macintosh HD`, `DADOS`, cartões SD), abra no Finder com `OPEN` ou ejete discos removíveis individualmente com `EJECT ⏏`, além dos indicadores de fonte de energia **`PWR.SOURCE`** (`IOKit`) e **`THERMAL`** (`ProcessInfo`).
* **26 Módulos com Esquemáticos Vetoriais Exclusivos**:
  * Cada módulo (`SW.01` a `SW.26`) possui uma gravura técnica vetorial própria dentro de uma moldura horológica de 12 marcações.
* **Fluidez Zero-Rolagem e `0.0%` de CPU em Segundo Plano**:
  * Orçamento vertical calibrado em `540×576pt` para que todas as 5 abas de domínio (`PWR`, `OPT`, `WKS`, `SIG`, `SEC`) exibam todos os seus interruptores sem barra de rolagem. A telemetria do kernel Mach (`host_processor_info` e `host_statistics64`) é lida apenas enquanto o painel está aberto na tela.
* **Execução 100% Nativa em User-Space**:
  * Construído diretamente sobre `Darwin.Mach`, `IOKit`, `CoreAudio`, `CoreGraphics`, `IOBluetooth`, `DiskArbitration`, `AppKit` e `CoreImage`. Sem Electron, sem processos residentes pesados e sem pacotes de terceiros.

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
