import CoreAudio
import Foundation
import OSLog
import TactileCore

public actor CoreAudioAdapter {
    public static let shared = CoreAudioAdapter()

    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "CoreAudioAdapter")

    public init() {}

    public func isDefaultInputMuted() -> Bool {
        guard let deviceID = defaultInputDeviceID() else { return false }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &muted)
        if status != noErr {
            logger.debug("Não foi possível ler estado de mute do dispositivo de entrada: \(status, privacy: .public)")
            return false
        }
        return muted != 0
    }

    public func setDefaultInputMuted(_ mute: Bool) -> Bool {
        guard let deviceID = defaultInputDeviceID() else { return false }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muteValue: UInt32 = mute ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &muteValue)
        if status != noErr {
            logger.error("Falha ao definir mute no CoreAudio: código \(status, privacy: .public)")
            return false
        }
        return true
    }

    private func defaultInputDeviceID() -> AudioObjectID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard status == noErr, deviceID != kAudioObjectUnknown else {
            return nil
        }
        return deviceID
    }
}
