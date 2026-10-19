import AppKit
import Carbon.HIToolbox

private let ringHotKeySignature: OSType = 0x5452_4E47 // "TRNG"

/// Atalhos globais via Carbon `RegisterEventHotKey`: não exige Accessibility nem Input Monitoring.
@MainActor
final class RingHotKeyCenter {
    static let shared = RingHotKeyCenter()

    private struct Entry {
        let reference: EventHotKeyRef
        let onPress: @MainActor () -> Void
        let onRelease: (@MainActor () -> Void)?
    }

    private var handlerReference: EventHandlerRef?
    private var entries: [UInt32: Entry] = [:]
    private var nextIdentifier: UInt32 = 1

    private init() {}

    /// Retorna o identificador do atalho, ou nil se o sistema recusar (ex.: atalho já em uso).
    func register(
        keyCode: Int,
        modifiers: Int,
        onPress: @escaping @MainActor () -> Void,
        onRelease: (@MainActor () -> Void)? = nil
    ) -> UInt32? {
        guard installHandlerIfNeeded() else { return nil }
        let identifier = nextIdentifier
        nextIdentifier += 1

        var reference: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            EventHotKeyID(signature: ringHotKeySignature, id: identifier),
            GetApplicationEventTarget(),
            0,
            &reference
        )
        guard status == noErr, let reference else { return nil }
        entries[identifier] = Entry(reference: reference, onPress: onPress, onRelease: onRelease)
        return identifier
    }

    func unregister(_ identifier: UInt32) {
        guard let entry = entries.removeValue(forKey: identifier) else { return }
        UnregisterEventHotKey(entry.reference)
    }

    fileprivate func dispatch(identifier: UInt32, kind: UInt32) {
        guard let entry = entries[identifier] else { return }
        if kind == UInt32(kEventHotKeyPressed) {
            entry.onPress()
        } else if kind == UInt32(kEventHotKeyReleased) {
            entry.onRelease?()
        }
    }

    private func installHandlerIfNeeded() -> Bool {
        if handlerReference != nil { return true }
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            ringHotKeyEventHandler,
            eventTypes.count,
            &eventTypes,
            nil,
            &handlerReference
        )
        return status == noErr
    }
}

private func ringHotKeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event else { return OSStatus(eventNotHandledErr) }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr, hotKeyID.signature == ringHotKeySignature else {
        return OSStatus(eventNotHandledErr)
    }
    let kind = GetEventKind(event)
    let identifier = hotKeyID.id
    MainActor.assumeIsolated {
        RingHotKeyCenter.shared.dispatch(identifier: identifier, kind: kind)
    }
    return noErr
}
