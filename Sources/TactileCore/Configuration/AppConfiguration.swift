import Foundation

public enum AppConfiguration {
    public static let applicationName = "TactileBar"
    public static let bundleIdentifier = "studio.tactile.TactileBar"
    public static let currentVersion = "1.4.0"
    public static let totalCatalogSwitchCount = 26

    public static let githubRepositoryOwner = "tr0drigues"
    public static let githubRepositoryName = "TactileBar"

    public static var sponsorURL: URL {
        URL(string: "https://github.com/sponsors/\(githubRepositoryOwner)")!
    }

    public static var githubRepositoryURL: URL {
        URL(string: "https://github.com/\(githubRepositoryOwner)/\(githubRepositoryName)")!
    }

    public static var githubLatestReleaseAPIURL: URL {
        URL(string: "https://api.github.com/repos/\(githubRepositoryOwner)/\(githubRepositoryName)/releases/latest")!
    }

    public enum SystemPreferenceURLs {
        public static let automationPrivacy = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        )!
        public static let accessibilityPrivacy = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )!
        public static let bluetoothPrivacy = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth"
        )!
    }

    public enum LayoutMetrics {
        public static let popoverWidth: Double = 540.0
        public static let popoverHeight: Double = 576.0
        public static let gridSpacing: Double = 8.0
        public static let cardCornerRadius: Double = 7.0
        public static let qrCodeDimensionPixels: Double = 220.0
    }
}
