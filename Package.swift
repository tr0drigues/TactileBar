// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TactileBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TactileCore", targets: ["TactileCore"]),
        .library(name: "SystemAdapters", targets: ["SystemAdapters"]),
        .library(name: "SwitchCatalog", targets: ["SwitchCatalog"]),
        .library(name: "TactileUI", targets: ["TactileUI"]),
        .executable(name: "TactileBar", targets: ["TactileBarApp"])
    ],
    targets: [
        .target(
            name: "TactileCore",
            path: "Sources/TactileCore"
        ),
        .target(
            name: "SystemAdapters",
            dependencies: ["TactileCore"],
            path: "Sources/SystemAdapters",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("IOBluetooth"),
                .linkedFramework("AppKit"),
                .linkedFramework("DiskArbitration")
            ]
        ),
        .target(
            name: "SwitchCatalog",
            dependencies: ["TactileCore", "SystemAdapters"],
            path: "Sources/SwitchCatalog"
        ),
        .target(
            name: "TactileUI",
            dependencies: ["TactileCore", "SwitchCatalog"],
            path: "Sources/TactileUI"
        ),
        .executableTarget(
            name: "TactileBarApp",
            dependencies: ["TactileCore", "SystemAdapters", "SwitchCatalog", "TactileUI"],
            path: "Sources/TactileBarApp"
        ),
        .testTarget(
            name: "TactileCoreTests",
            dependencies: ["TactileCore", "SystemAdapters", "SwitchCatalog"],
            path: "Tests/TactileCoreTests"
        )
    ]
)
