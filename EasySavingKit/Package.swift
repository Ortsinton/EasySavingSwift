// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "EasySavingKit",
    // iOS 17 for mobile devices, macOS 14 for CLI
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "EasySavingCore", targets: ["EasySavingCore"]),
        .library(name: "EasySavingData", targets: ["EasySavingData"]),
    ],
    dependencies: [
        // Tooling-only command plugins; never linked into any product.
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.57.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.55.0"),
    ],
    targets: [
        .target(name: "EasySavingCore"),
        .target(name: "EasySavingData", dependencies: ["EasySavingCore"]),
        .testTarget(name: "EasySavingCoreTests", dependencies: ["EasySavingCore"]),
        .testTarget(name: "EasySavingDataTests", dependencies: ["EasySavingData"]),
    ],
    
)
