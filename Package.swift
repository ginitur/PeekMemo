// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeekMeow",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "PeekMeow", targets: ["PeekMeow"]),
        .executable(name: "PeekMeowCoreTests", targets: ["PeekMeowCoreTests"]),
        .library(name: "PeekMeowCore", targets: ["PeekMeowCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1"),
    ],
    targets: [
        .target(
            name: "PeekMeowCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/PeekMeowCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "PeekMeow",
            dependencies: [
                "PeekMeowCore",
            ],
            path: "Sources/PeekMeow",
            exclude: [
                "Resources/Info.plist",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        // Executable suite, not XCTest / Swift Testing.
        // Command Line Tools does not ship XCTest, and Swift Testing cannot
        // dlopen Testing.framework from a CLT-built .xctest bundle.
        .executableTarget(
            name: "PeekMeowCoreTests",
            dependencies: [
                "PeekMeowCore",
            ],
            path: "Tests/PeekMeowCoreTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
