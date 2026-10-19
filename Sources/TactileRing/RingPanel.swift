import AppKit
import SwiftUI

/// Recebe os cliques do anel diretamente, mesmo com o app inativo e o painel sem foco.
/// Não depende de monitor de eventos local, que pode não ver cliques num painel não ativável.
final class RingHostingView: NSHostingView<RingView> {
    var onPrimaryClick: (() -> Void)?
    var onSecondaryClick: (() -> Void)?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        return bounds.contains(local) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        onPrimaryClick?()
    }

    override func rightMouseDown(with event: NSEvent) {
        onSecondaryClick?()
    }
}

/// Painel flutuante, sem borda, que nunca ativa o app nem rouba o foco da janela atual.
final class RingPanel: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(origin: .zero, size: RingMetrics.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        ignoresMouseEvents = true
        animationBehavior = .none
        self.contentView = contentView
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Mostra o painel centrado no ponto, ajustado para caber na tela. Retorna o centro real do anel.
    func present(at point: NSPoint) -> NSPoint {
        let screen = NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
        let size = RingMetrics.panelSize
        var origin = NSPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - size.width)
            origin.y = min(max(origin.y, visible.minY), visible.maxY - size.height)
        }
        setFrame(NSRect(origin: origin, size: size), display: true)
        alphaValue = 1
        orderFrontRegardless()
        return NSPoint(x: origin.x + size.width / 2, y: origin.y + size.height / 2)
    }

    func dismiss() {
        orderOut(nil)
    }
}
