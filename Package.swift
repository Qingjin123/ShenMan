// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ShenMan",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ShenMan",
            targets: ["ShenMan"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/ml-explore/mlx-swift.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/Blaizzy/mlx-audio-swift.git",
            branch: "main"
        )
    ],
    targets: [
        .executableTarget(
            name: "ShenMan",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXFast", package: "mlx-swift"),
                .product(name: "MLXAudioSTT", package: "mlx-audio-swift"),
                .product(name: "MLXAudioCore", package: "mlx-audio-swift")
            ],
            path: "ShenMan",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                // Swift 6 语言模式
                .swiftLanguageMode(.v6),
                // 启用严格的并发检查
                .enableExperimentalFeature("StrictConcurrency"),
                // 启用 Sendable 检查
                .unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"])
            ]
        ),
        .testTarget(
            name: "ShenManTests",
            dependencies: ["ShenMan"],
            path: "ShenManTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
