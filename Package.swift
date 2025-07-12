// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BrainSAIT-MCP",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BrainSAITMCP",
            targets: ["BrainSAITMCP"]
        ),
        .executable(
            name: "BrainSAITDemo",
            targets: ["BrainSAITDemo"]
        ),
        // TODO: Re-enable when MCP SDK integration is complete
        // .executable(
        //     name: "BrainSAITHealthcareServer",
        //     targets: ["BrainSAITHealthcareServer"]
        // ),
        // .executable(
        //     name: "BrainSAITClient",
        //     targets: ["BrainSAITClient"]
        // )
    ],
    dependencies: [
        // MCP Swift SDK dependency
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.7.1"),
        // Logging support
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        // Service lifecycle for production deployments
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
        // Crypto for healthcare data encryption
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        // Argument parser for CLI tools
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        .target(
            name: "BrainSAITMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .executableTarget(
            name: "BrainSAITDemo",
            dependencies: [
                "BrainSAITMCP"
            ]
        ),
        // TODO: Re-enable when MCP SDK integration is complete
        // .executableTarget(
        //     name: "BrainSAITHealthcareServer",
        //     dependencies: [
        //         "BrainSAITMCP",
        //         .product(name: "ArgumentParser", package: "swift-argument-parser")
        //     ]
        // ),
        // .executableTarget(
        //     name: "BrainSAITClient",
        //     dependencies: [
        //         "BrainSAITMCP",
        //         .product(name: "ArgumentParser", package: "swift-argument-parser")
        //     ]
        // ),
        .testTarget(
            name: "BrainSAITMCPTests",
            dependencies: ["BrainSAITMCP"]
        )
    ]
)