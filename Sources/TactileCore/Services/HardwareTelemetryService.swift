import Darwin
import Foundation
import IOKit.ps

public struct SystemHardwareTelemetrySnapshot: Sendable, Equatable {
    public let cpuTotalRatio: Double
    public let cpuUserPercent: Int
    public let cpuSystemPercent: Int
    public let cpuTotalPercent: Int

    public let memoryUsedRatio: Double
    public let memoryUsedPercent: Int
    public let memoryFormattedRatio: String

    public let powerLevelRatio: Double
    public let powerPercentLabel: String
    public let powerSourceLabel: String

    public let thermalStateLabel: String
    public let isThermalElevated: Bool

    public static let initial = SystemHardwareTelemetrySnapshot(
        cpuTotalRatio: 0.08,
        cpuUserPercent: 5,
        cpuSystemPercent: 3,
        cpuTotalPercent: 8,
        memoryUsedRatio: 0.50,
        memoryUsedPercent: 50,
        memoryFormattedRatio: "0.0 / 0.0 GB",
        powerLevelRatio: 1.0,
        powerPercentLabel: "100%",
        powerSourceLabel: "AC POWER",
        thermalStateLabel: "NOMINAL",
        isThermalElevated: false
    )
}

@MainActor
public final class HardwareTelemetryService {
    public static let shared = HardwareTelemetryService()

    private var previousUserTicks: UInt64 = 0
    private var previousSystemTicks: UInt64 = 0
    private var previousIdleTicks: UInt64 = 0
    private var previousNiceTicks: UInt64 = 0

    private init() {
        // Capture initial baseline tick counters at startup so the first popover sample has a valid delta.
        _ = readCPUTicks()
    }

    public func captureSnapshot() -> SystemHardwareTelemetrySnapshot {
        let (cpuRatio, userPct, sysPct, totalPct) = sampleCPULoad()
        let (memRatio, memPct, memFormatted) = sampleMemoryUsage()
        let (pwrRatio, pwrPctLabel, pwrSourceLabel) = samplePowerStatus()
        let (thermalLabel, isThermalElevated) = sampleThermalState()

        return SystemHardwareTelemetrySnapshot(
            cpuTotalRatio: cpuRatio,
            cpuUserPercent: userPct,
            cpuSystemPercent: sysPct,
            cpuTotalPercent: totalPct,
            memoryUsedRatio: memRatio,
            memoryUsedPercent: memPct,
            memoryFormattedRatio: memFormatted,
            powerLevelRatio: pwrRatio,
            powerPercentLabel: pwrPctLabel,
            powerSourceLabel: pwrSourceLabel,
            thermalStateLabel: thermalLabel,
            isThermalElevated: isThermalElevated
        )
    }

    // MARK: - Mach Kernel CPU Load

    private func readCPUTicks() -> (user: UInt64, system: UInt64, idle: UInt64, nice: UInt64)? {
        var processorCount: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let info = cpuInfo else {
            return nil
        }

        // Always deallocate the Mach kernel out-of-line memory buffer immediately after reading.
        defer {
            let byteCount = vm_size_t(Int(numCPUInfo) * MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), byteCount)
        }

        var totalUser: UInt64 = 0
        var totalSystem: UInt64 = 0
        var totalIdle: UInt64 = 0
        var totalNice: UInt64 = 0

        let cpuCount = Int(processorCount)
        for core in 0..<cpuCount {
            let base = Int(CPU_STATE_MAX) * core
            totalUser += UInt64(max(0, info[base + Int(CPU_STATE_USER)]))
            totalSystem += UInt64(max(0, info[base + Int(CPU_STATE_SYSTEM)]))
            totalIdle += UInt64(max(0, info[base + Int(CPU_STATE_IDLE)]))
            totalNice += UInt64(max(0, info[base + Int(CPU_STATE_NICE)]))
        }

        return (totalUser, totalSystem, totalIdle, totalNice)
    }

    private func sampleCPULoad() -> (ratio: Double, userPct: Int, sysPct: Int, totalPct: Int) {
        guard let current = readCPUTicks() else {
            return (0.05, 3, 2, 5)
        }

        let dUser = current.user >= previousUserTicks ? current.user - previousUserTicks : 0
        let dSystem = current.system >= previousSystemTicks ? current.system - previousSystemTicks : 0
        let dIdle = current.idle >= previousIdleTicks ? current.idle - previousIdleTicks : 0
        let dNice = current.nice >= previousNiceTicks ? current.nice - previousNiceTicks : 0

        previousUserTicks = current.user
        previousSystemTicks = current.system
        previousIdleTicks = current.idle
        previousNiceTicks = current.nice

        let dTotal = dUser + dSystem + dIdle + dNice
        guard dTotal > 0 else {
            return (0.05, 3, 2, 5)
        }

        let userRatio = Double(dUser + dNice) / Double(dTotal)
        let sysRatio = Double(dSystem) / Double(dTotal)
        let totalRatio = min(max(userRatio + sysRatio, 0.01), 1.0)

        let userPct = Int((userRatio * 100.0).rounded())
        let sysPct = Int((sysRatio * 100.0).rounded())
        let totalPct = min(max(userPct + sysPct, 1), 100)

        return (totalRatio, userPct, sysPct, totalPct)
    }

    // MARK: - Mach Kernel VM Memory Pressure

    private func sampleMemoryUsage() -> (ratio: Double, pct: Int, formatted: String) {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        guard totalBytes > 0 else {
            return (0.5, 50, "0.0 / 0.0 GB")
        }

        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let kernResult = withUnsafeMutablePointer(to: &vmStats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }

        guard kernResult == KERN_SUCCESS else {
            return (0.5, 50, "0.0 / 0.0 GB")
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let activePages = UInt64(vmStats.active_count)
        let wiredPages = UInt64(vmStats.wire_count)
        let compressedPages = UInt64(vmStats.compressor_page_count)

        let usedBytes = min((activePages + wiredPages + compressedPages) * pageSize, totalBytes)
        let ratio = min(max(Double(usedBytes) / Double(totalBytes), 0.01), 1.0)
        let pct = Int((ratio * 100.0).rounded())

        let bytesPerGB = 1_073_741_824.0
        let usedGB = Double(usedBytes) / bytesPerGB
        let totalGB = Double(totalBytes) / bytesPerGB
        let formatted = String(format: "%.1f / %.0f GB", usedGB, totalGB)

        return (ratio, pct, formatted)
    }

    // MARK: - IOKit Power & Battery Source

    private func samplePowerStatus() -> (ratio: Double, pctLabel: String, sourceLabel: String) {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              !list.isEmpty else {
            return (1.0, "AC", "LINE POWER")
        }

        for source in list {
            guard let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            let currentCap = desc[kIOPSCurrentCapacityKey as String] as? Int ?? 100
            let maxCap = max(desc[kIOPSMaxCapacityKey as String] as? Int ?? 100, 1)
            let powerState = desc[kIOPSPowerSourceStateKey as String] as? String ?? ""
            let isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false

            let ratio = min(max(Double(currentCap) / Double(maxCap), 0.02), 1.0)
            let pct = Int((ratio * 100.0).rounded())
            let pctLabel = "\(pct)%"

            let sourceLabel: String
            if isCharging {
                sourceLabel = "CHARGING ⚡"
            } else if powerState == kIOPSACPowerValue {
                sourceLabel = "AC CHARGED"
            } else {
                sourceLabel = "ON BATTERY"
            }

            return (ratio, pctLabel, sourceLabel)
        }

        return (1.0, "AC", "LINE POWER")
    }

    // MARK: - macOS ProcessInfo Thermal State

    private func sampleThermalState() -> (label: String, isElevated: Bool) {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            return ("NOMINAL", false)
        case .fair:
            return ("WARM", false)
        case .serious:
            return ("HIGH", true)
        case .critical:
            return ("CRITICAL", true)
        @unknown default:
            return ("NOMINAL", false)
        }
    }
}
