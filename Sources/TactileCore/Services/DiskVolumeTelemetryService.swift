import AppKit
import Foundation

public struct MountedVolumeInfo: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let url: URL
    public let totalBytes: Int64
    public let freeBytes: Int64
    public let isEjectable: Bool

    public var usedBytes: Int64 {
        max(totalBytes - freeBytes, 0)
    }

    public var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0.0), 1.0)
    }

    public var formattedFreeGB: String {
        let gb = Double(freeBytes) / 1_000_000_000.0
        return String(format: "%.0f GB FREE", gb)
    }

    public var formattedUsedRatio: String {
        let usedGB = Double(usedBytes) / 1_000_000_000.0
        let totalGB = Double(totalBytes) / 1_000_000_000.0
        return String(format: "%.0f / %.0f GB", usedGB, totalGB)
    }

    public var kindBadge: String {
        isEjectable ? "EXT" : "SYS"
    }
}

public enum DiskVolumeTelemetryService {
    public static func listMountedVolumes() -> [MountedVolumeInfo] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeIsRemovableKey,
            .volumeIsEjectableKey,
            .volumeIsInternalKey,
            .volumeIsBrowsableKey
        ]

        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []

        var results: [MountedVolumeInfo] = []

        for url in urls {
            let path = url.path
            if path.hasPrefix("/System/Volumes/") || path == "/Volumes/Recovery" {
                continue
            }

            let values = try? url.resourceValues(forKeys: Set(keys))
            let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path)

            let name = values?.volumeName ?? url.lastPathComponent
            let totalFromURL = values?.volumeTotalCapacity.map { Int64($0) }
            let totalFromFS = (attrs?[.systemSize] as? NSNumber)?.int64Value
            let totalBytes = totalFromURL ?? totalFromFS ?? 0

            guard totalBytes > 0 else { continue }

            let freeImportant = values?.volumeAvailableCapacityForImportantUsage
            let freeStandard = values?.volumeAvailableCapacity.map { Int64($0) }
            let freeFromFS = (attrs?[.systemFreeSize] as? NSNumber)?.int64Value

            // Em volumes externos (ex: ExFAT/APFS externo), volumeAvailableCapacity / systemFreeSize
            // reflete o espaço livre real sem inflar com purgeable cache do macOS.
            let isRoot = (path == "/")
            let freeBytes: Int64
            if isRoot {
                freeBytes = freeImportant ?? freeStandard ?? freeFromFS ?? 0
            } else {
                freeBytes = freeStandard ?? freeFromFS ?? freeImportant ?? 0
            }

            let isRemovable = values?.volumeIsRemovable ?? false
            let isEjectableFlag = values?.volumeIsEjectable ?? false
            let isInternal = values?.volumeIsInternal ?? (path == "/")
            let isEjectable = !isRoot && (isRemovable || isEjectableFlag || !isInternal)

            results.append(
                MountedVolumeInfo(
                    id: path,
                    name: name,
                    path: path,
                    url: url,
                    totalBytes: totalBytes,
                    freeBytes: min(max(freeBytes, 0), totalBytes),
                    isEjectable: isEjectable
                )
            )
        }

        return results.sorted { lhs, rhs in
            if lhs.path == "/" { return true }
            if rhs.path == "/" { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    @MainActor
    public static func ejectVolume(_ volume: MountedVolumeInfo) -> Bool {
        guard volume.isEjectable else { return false }
        do {
            try NSWorkspace.shared.unmountAndEjectDevice(at: volume.url)
            return true
        } catch {
            return false
        }
    }

    @MainActor
    public static func revealInFinder(_ volume: MountedVolumeInfo) {
        NSWorkspace.shared.open(volume.url)
    }
}
