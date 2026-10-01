// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PeekMemo",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "PeekMemo", targets: ["PeekMemo"]),
        .executable(name: "PeekMemoCoreTests", targets: ["PeekMemoCoreTests"]),
        .library(name: "PeekMemoCore", targets: ["PeekMemoCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.11.1"),
    ],
    targets: [
        .target(
            name: "PeekMemoCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/PeekMemoCore",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .executableTarget(
            name: "PeekMemo",
            dependencies: [
                "PeekMemoCore",
            ],
            path: "Sources/PeekMemo",
            exclude: [
                "Resources/Info.plist",
            ],
            resources: [
                .process("Resources/PeekMemoMark.png"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        // Executable suite, not XCTest / Swift Testing.
        // Command Line Tools does not ship XCTest, and Swift Testing cannot
        // dlopen Testing.framework from a CLT-built .xctest bundle.
        .executableTarget(
            name: "PeekMemoCoreTests",
            dependencies: [
                "PeekMemoCore",
            ],
            path: "Tests/PeekMemoCoreTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
