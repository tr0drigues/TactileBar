import Foundation
import IOBluetooth

public struct BluetoothDeviceItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let address: String
    public let isConnected: Bool
    public let isAudioDevice: Bool
    public let kindBadge: String

    public init(
        id: String,
        name: String,
        address: String,
        isConnected: Bool,
        isAudioDevice: Bool,
        kindBadge: String
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.isConnected = isConnected
        self.isAudioDevice = isAudioDevice
        self.kindBadge = kindBadge
    }
}

public enum BluetoothDeviceService {
    public static func listPairedDevices() -> [BluetoothDeviceItem] {
        guard let rawDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return []
        }

        var items: [BluetoothDeviceItem] = []

        for device in rawDevices {
            let major = device.deviceClassMajor
            // Major Class: 4 = Audio/Video (Fones, Caixas), 5 = Peripheral (Controles, Teclados, Mouses)
            // Ignora entradas major=0 (computadores/outros) a menos que estejam ativamente conectadas
            let isAudio = (major == kBluetoothDeviceClassMajorAudio)
            let isPeripheral = (major == kBluetoothDeviceClassMajorPeripheral)
            let connected = device.isConnected()

            guard isAudio || isPeripheral || connected else {
                continue
            }

            let address = device.addressString ?? UUID().uuidString
            let rawName = device.nameOrAddress ?? address
            let badge: String
            if isAudio {
                badge = "AUDIO"
            } else if isPeripheral {
                badge = "CTRL"
            } else {
                badge = "BT"
            }

            items.append(
                BluetoothDeviceItem(
                    id: address,
                    name: rawName,
                    address: address,
                    isConnected: connected,
                    isAudioDevice: isAudio,
                    kindBadge: badge
                )
            )
        }

        return items.sorted { lhs, rhs in
            if lhs.isConnected != rhs.isConnected {
                return lhs.isConnected && !rhs.isConnected
            }
            if lhs.isAudioDevice != rhs.isAudioDevice {
                return lhs.isAudioDevice && !rhs.isAudioDevice
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    public static func setConnection(address: String, connect: Bool) async -> Bool {
        await Task.detached(priority: .userInitiated) {
            guard let rawDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice],
                  let target = rawDevices.first(where: { $0.addressString == address })
            else {
                return false
            }

            if connect {
                if target.isConnected() { return true }
                let status = target.openConnection()
                return status == kIOReturnSuccess || target.isConnected()
            } else {
                if !target.isConnected() { return true }
                let status = target.closeConnection()
                return status == kIOReturnSuccess || !target.isConnected()
            }
        }.value
    }
}
