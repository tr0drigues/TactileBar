import Foundation
import OSLog

public struct ReleaseUpdateInfo: Equatable, Sendable {
    public let latestVersion: String
    public let releasePageURL: URL

    public init(latestVersion: String, releasePageURL: URL) {
        self.latestVersion = latestVersion
        self.releasePageURL = releasePageURL
    }
}

public actor GitHubReleaseChecker {
    private struct GitHubReleasePayload: Decodable {
        let tagName: String
        let htmlURL: URL

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }

    private let logger = Logger(subsystem: AppConfiguration.bundleIdentifier, category: "GitHubReleaseChecker")
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func checkForUpdate(currentVersion: String = AppConfiguration.currentVersion) async -> ReleaseUpdateInfo? {
        var request = URLRequest(url: AppConfiguration.githubLatestReleaseAPIURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10.0

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            let payload = try JSONDecoder().decode(GitHubReleasePayload.self, from: data)
            let normalizedRemote = Self.normalizeSemanticVersion(payload.tagName)
            let normalizedLocal = Self.normalizeSemanticVersion(currentVersion)

            if Self.isVersion(normalizedRemote, newerThan: normalizedLocal) {
                return ReleaseUpdateInfo(latestVersion: normalizedRemote, releasePageURL: payload.htmlURL)
            }
            return nil
        } catch {
            logger.debug("Verificação de release no GitHub não concluída: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    public static func normalizeSemanticVersion(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "^[vV]", with: "", options: .regularExpression)
    }

    public static func isVersion(_ candidate: String, newerThan baseline: String) -> Bool {
        let candidateParts = candidate.split(separator: ".").compactMap { Int($0) }
        let baselineParts = baseline.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(candidateParts.count, baselineParts.count)

        for index in 0..<maxCount {
            let cVal = index < candidateParts.count ? candidateParts[index] : 0
            let bVal = index < baselineParts.count ? baselineParts[index] : 0
            if cVal != bVal {
                return cVal > bVal
            }
        }
        return false
    }
}
