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
    targets: [
        .target(
            name: "PeekMemoCore",
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
