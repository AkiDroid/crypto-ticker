// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "crypto-ticker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CryptoTickerApp", targets: ["CryptoTickerApp"])
    ],
    targets: [
        .executableTarget(
            name: "CryptoTickerApp",
            path: "Sources/CryptoTickerApp"
        ),
        .testTarget(
            name: "CryptoTickerAppTests",
            dependencies: ["CryptoTickerApp"],
            path: "Tests/CryptoTickerAppTests",
            swiftSettings: [
                .unsafeFlags([
                    "-F",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
                ])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker",
                    "-rpath",
                    "-Xlinker",
                    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-framework",
                    "Testing"
                ])
            ]
        )
    ]
)
