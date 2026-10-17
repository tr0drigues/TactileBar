import Foundation
import IOKit.pwr_mgt
import OSLog
import TactileCore

public actor PowerAssertionAdapter {
    public static let shared = PowerAssertionAdapter()

    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "PowerAssertionAdapter")
    private var activeAssertionID: IOPMAssertionID = 0
    private var isAssertionHeld = false

    public init() {}

    public func isKeepAwakeActive() -> Bool {
        isAssertionHeld
    }

    public func setKeepAwake(enabled: Bool) -> Bool {
        if enabled {
            guard !isAssertionHeld else { return true }
            var newID: IOPMAssertionID = 0
            let reason = "TactileBar User Requested Keep Awake" as CFString
            let assertionType = kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
            let result = IOPMAssertionCreateWithName(
                assertionType,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &newID
            )
            if result == kIOReturnSuccess {
                activeAssertionID = newID
                isAssertionHeld = true
                return true
            }
            logger.error("Falha ao criar asserção IOKit: código \(result, privacy: .public)")
            return false
        } else {
            guard isAssertionHeld else { return true }
            let result = IOPMAssertionRelease(activeAssertionID)
            if result == kIOReturnSuccess {
                activeAssertionID = 0
                isAssertionHeld = false
                return true
            }
            logger.error("Falha ao liberar asserção IOKit: código \(result, privacy: .public)")
            return false
        }
    }

    public func triggerImmediateDisplaySleep() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            logger.error("Erro ao acionar repouso do monitor: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    public func readLowPowerModeEnabled() -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return false }
            return output.range(of: #"lowpowermode\s+1"#, options: .regularExpression) != nil
        } catch {
            logger.debug("Leitura de pmset falhou: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    @MainActor
    public func setLowPowerModeWithAdminPrompt(enabled: Bool) -> Bool {
        let targetValue = enabled ? 1 : 0
        let scriptSource = "do shell script \"/usr/bin/pmset -a lowpowermode \(targetValue)\" with administrator privileges"
        guard let script = NSAppleScript(source: scriptSource) else { return false }
        var errorDict: NSDictionary?
        _ = script.executeAndReturnError(&errorDict)
        return errorDict == nil
    }
}
