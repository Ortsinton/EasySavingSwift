// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "EasySavingKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "EasySavingCore", targets: ["EasySavingCore"]),
        .library(name: "EasySavingData", targets: ["EasySavingData"]),
    ],
    targets: [
        .target(name: "EasySavingCore"),
        .target(name: "EasySavingData", dependencies: ["EasySavingCore"]),
        .testTarget(name: "EasySavingCoreTests", dependencies: ["EasySavingCore"]),
        .testTarget(name: "EasySavingDataTests", dependencies: ["EasySavingData"]),
    ]
)
