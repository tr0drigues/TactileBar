# TactileBar

**Utilitário modular de barra de menus para macOS 14+ desenvolvido em Swift 6 sob a filosofia visual *Tactile Telemetry*.**

![Tactile Telemetry Atlas](tactile-telemetry-canvas.png)

---

## Arquitetura e Mecanismos

O **TactileBar** reúne **26 interruptores de sistema** divididos em **5 domínios funcionais** (`PWR`, `OPT`, `WKS`, `SIG`, `SEC`), operando integralmente em *user-space* e sem dependências de bibliotecas de terceiros.

| Domínio | Código | Módulos (`SW.01` – `SW.26`) | Subsistemas macOS |
| :--- | :--- | :--- | :--- |
| **Power & Sleep** | `M.01 PWR` | `SW.01` Keep Awake, `SW.02` Display Sleep, `SW.03` Screen Saver, `SW.04` Low Power Mode, `SW.05` Energy Mode | `IOKit.pwr_mgt`, `/usr/bin/pmset`, `ScreenSaverEngine` |
| **Optics & Display** | `M.02 OPT` | `SW.06` Dark Mode, `SW.07` Night Shift, `SW.08` True Tone, `SW.09` Resolution | `System Events`, `CoreGraphics`, `Displays Settings` |
| **Workspace & Dock** | `M.03 WKS` | `SW.10` Hide Desktop, `SW.11` Hidden Files, `SW.12` Hide Dock, `SW.13` Hide Windows, `SW.14` Stage Manager, `SW.15` Hide Widgets | `com.apple.finder`, `com.apple.dock`, `com.apple.WindowManager`, `NSWorkspace` |
| **Acoustic & RF** | `M.04 SIG` | `SW.16` Mute Mic, `SW.17` AirPods Connect, `SW.18` Play Music | `CoreAudio`, `IOBluetooth`, `Music / Spotify AppleEvents` |
| **Security & Purge** | `M.05 SEC` | `SW.19` Screen Clean, `SW.20` Lock Keyboard, `SW.21` Lock Screen, `SW.22` Empty Trash, `SW.23` Pasteboard, `SW.24` Eject Disks, `SW.25` Xcode Clean, `SW.26` Do Not Disturb | `NSWindow.Level.screenSaver`, `NSEvent`, `NSPasteboard`, `FileManager`, `DiskArbitration` |

---

## Compilação e Execução Local

### Requisitos
* macOS 14.0 (Sonoma) ou superior
* Swift 6.0+ / Xcode Command Line Tools

### Comandos
```bash
# Executar a suíte de testes unitários
swift test

# Gerar o pacote TactileBar.app assinado (Ad-Hoc)
chmod +x scripts/build-app.sh
./scripts/build-app.sh

# Iniciar o aplicativo
open TactileBar.app
```

> **Nota sobre o Gatekeeper (Downloads do GitHub Releases)**:  
> Como o binário distribuído nas Releases utiliza assinatura gratuita *Ad-Hoc*, na primeira execução após baixar da internet, remova o atributo de quarentena com:
> ```bash
> xattr -cr /Applications/TactileBar.app
> ```

---

## Apoie o Projeto (GitHub Sponsors)

Se o **TactileBar** economiza o seu tempo no dia a dia, considere apoiar o desenvolvimento contínuo via **GitHub Sponsors**:
* **GitHub Sponsors**: [https://github.com/sponsors/tr0drigues](https://github.com/sponsors/tr0drigues)

O aplicativo também inclui um gerador nativo de QR Code (`CoreImage.CIQRCodeGenerator`) acessível pelo botão **Support Craftsmanship ☕** no rodapé do painel.

---

## Licença

Distribuído sob a [MIT License](LICENSE).
