// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ScreenOCR",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ScreenOCR", targets: ["ScreenOCR"])
    ],
    dependencies: [
        // No external dependencies for now to keep it simple and robust
    ],
    targets: [
        .executableTarget(
            name: "ScreenOCR",
            dependencies: [],
            path: "Sources/ScreenOCR",
            resources: []
        )
    ]
)
