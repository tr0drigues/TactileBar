import AppKit
import Foundation

@MainActor
public final class ScreenCleanShieldController {
    public static let shared = ScreenCleanShieldController()

    private var shieldWindows: [NSWindow] = []
    private var localKeyEventMonitor: Any?
    public private(set) var isScreenCleanActive = false
    public private(set) var isKeyboardLocked = false
    public var onStateChanged: (() -> Void)?

    private init() {}

    public func setScreenCleanMode(enabled: Bool) {
        guard enabled != isScreenCleanActive else { return }
        if enabled {
            isScreenCleanActive = true
            presentBlackoutShieldOnAllScreens()
            installKeyboardSuppression()
        } else {
            isScreenCleanActive = false
            dismissBlackoutShields()
            if !isKeyboardLocked {
                removeKeyboardSuppression()
            }
        }
        onStateChanged?()
    }

    public func setKeyboardLock(enabled: Bool) {
        guard enabled != isKeyboardLocked else { return }
        isKeyboardLocked = enabled
        if enabled {
            installKeyboardSuppression()
        } else if !isScreenCleanActive {
            removeKeyboardSuppression()
        }
        onStateChanged?()
    }

    private func presentBlackoutShieldOnAllScreens() {
        dismissBlackoutShields()
        for screen in NSScreen.screens {
            let panel = ShieldOverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            panel.level = .screenSaver
            panel.backgroundColor = NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.06, alpha: 1.0)
            panel.isOpaque = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.onMouseClickExit = { [weak self] in
                self?.setScreenCleanMode(enabled: false)
            }
            panel.makeKeyAndOrderFront(nil)
            shieldWindows.append(panel)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func dismissBlackoutShields() {
        for window in shieldWindows {
            window.orderOut(nil)
        }
        shieldWindows.removeAll()
    }

    private func installKeyboardSuppression() {
        guard localKeyEventMonitor == nil else { return }
        localKeyEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { _ in
            nil
        }
    }

    private func removeKeyboardSuppression() {
        if let monitor = localKeyEventMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyEventMonitor = nil
        }
    }
}

private final class ShieldOverlayWindow: NSWindow {
    var onMouseClickExit: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupOverlayLabel(in: contentRect)
    }

    private func setupOverlayLabel(in frame: NSRect) {
        let container = NSView(frame: NSRect(origin: .zero, size: frame.size))
        let label = NSTextField(labelWithString: "SCREEN CLEANING MODE // KEYBOARD SHIELD ACTIVE\nCLICK MOUSE ANYWHERE TO EXIT")
        label.alignment = .center
        label.font = NSFont.monospacedSystemFont(ofSize: 15, weight: .semibold)
        label.textColor = NSColor(calibratedRed: 0.96, green: 0.62, blue: 0.04, alpha: 0.85)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        contentView = container
    }

    override func mouseDown(with event: NSEvent) {
        onMouseClickExit?()
    }

    override func keyDown(with event: NSEvent) {}
}
