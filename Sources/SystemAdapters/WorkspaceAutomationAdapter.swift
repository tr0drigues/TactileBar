import AppKit
import Foundation
import OSLog
import TactileCore

public actor WorkspaceAutomationAdapter {
    public static let shared = WorkspaceAutomationAdapter()

    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "WorkspaceAutomationAdapter")

    public init() {}

    public func isDarkModeEnabled() -> Bool {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    }

    @MainActor
    public func setDarkMode(enabled: Bool) -> Bool {
        let targetLiteral = enabled ? "true" : "false"
        let script = """
        tell application "System Events"
            tell appearance preferences
                set dark mode to \(targetLiteral)
            end tell
        end tell
        """
        return executeAppleScript(script)
    }

    public func readDefaultsBool(domain: String, key: String, defaultValue: Bool = false) -> Bool {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", domain, key]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return defaultValue }
            let raw = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() ?? ""
            return raw == "1" || raw == "true"
        } catch {
            logger.debug("Leitura de defaults (\(domain, privacy: .public).\(key, privacy: .public)) usou padrão: \(error.localizedDescription, privacy: .public)")
            return defaultValue
        }
    }

    public func writeDefaultsBool(domain: String, key: String, value: Bool, restartProcess: String? = nil) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", domain, key, "-bool", value ? "true" : "false"]

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return false }

            if let targetProcess = restartProcess {
                let killProcess = Process()
                killProcess.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
                killProcess.arguments = [targetProcess]
                try killProcess.run()
                killProcess.waitUntilExit()
            }
            return true
        } catch {
            logger.error("Falha ao gravar defaults (\(domain, privacy: .public).\(key, privacy: .public)): \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    public func launchScreenSaver() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "ScreenSaverEngine"]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            logger.error("Erro ao iniciar ScreenSaverEngine: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    @MainActor
    public func clearGeneralPasteboard() -> Int {
        NSPasteboard.general.clearContents()
    }

    @MainActor
    public func hideAllOtherApplications() {
        NSWorkspace.shared.hideOtherApplications()
    }

    @MainActor
    public func lockScreenImmediate() -> Bool {
        let script = """
        tell application "System Events" to keystroke "q" using {command down, control down}
        """
        return executeAppleScript(script)
    }

    @MainActor
    public func emptySystemTrash() -> Bool {
        let script = """
        tell application "Finder"
            if (count of items in trash) > 0 then
                empty trash
            end if
        end tell
        """
        return executeAppleScript(script)
    }

    @MainActor
    public func toggleMusicPlayback() -> Bool {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to playpause
        else
            tell application "Music" to playpause
        end if
        """
        return executeAppleScript(script)
    }

    public func ejectRemovableVolumes() -> Int {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.volumeIsRemovableKey, .volumeIsEjectableKey, .volumeIsInternalKey]
        guard let urls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return 0
        }

        var ejectedCount = 0
        for volumeURL in urls {
            do {
                let values = try volumeURL.resourceValues(forKeys: Set(keys))
                let isRemovable = values.volumeIsRemovable ?? false
                let isEjectable = values.volumeIsEjectable ?? false
                let isInternal = values.volumeIsInternal ?? true

                if isRemovable || isEjectable || !isInternal {
                    try NSWorkspace.shared.unmountAndEjectDevice(at: volumeURL)
                    ejectedCount += 1
                }
            } catch {
                logger.debug("Volume \(volumeURL.lastPathComponent, privacy: .public) ignorado na ejeção: \(error.localizedDescription, privacy: .public)")
            }
        }
        return ejectedCount
    }

    public func calculateXcodeDerivedDataSizeFormatted() -> String {
        let derivedDataURL = xcodeDerivedDataURL()
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: derivedDataURL.path) else {
            return "0 MB"
        }

        var totalBytes: Int64 = 0
        if let enumerator = fileManager.enumerator(
            at: derivedDataURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalBytes += Int64(size)
                }
            }
        }

        if totalBytes == 0 {
            return "ZERO"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes).uppercased()
    }

    public func purgeXcodeDerivedData() -> Bool {
        let derivedDataURL = xcodeDerivedDataURL()
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: derivedDataURL.path) else {
            return true
        }

        do {
            let children = try fileManager.contentsOfDirectory(at: derivedDataURL, includingPropertiesForKeys: nil)
            for child in children {
                try fileManager.removeItem(at: child)
            }
            return true
        } catch {
            logger.error("Erro ao limpar DerivedData: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func xcodeDerivedDataURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)
    }

    @MainActor
    private func executeAppleScript(_ source: String) -> Bool {
        guard let script = NSAppleScript(source: source) else { return false }
        var errorInfo: NSDictionary?
        _ = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            logger.debug("AppleScript reportou erro: \(String(describing: errorInfo), privacy: .public)")
            return false
        }
        return true
    }
}
