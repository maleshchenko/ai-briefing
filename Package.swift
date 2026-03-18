// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ai-briefing",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .executable(
            name: "ai-briefing",
            targets: ["ai-briefing"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ai-briefing"
        )
    ]
)
