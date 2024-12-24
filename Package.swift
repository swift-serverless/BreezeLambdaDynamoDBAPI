// swift-tools-version: 6.0

import PackageDescription

#if os(macOS)
let platforms: [PackageDescription.SupportedPlatform]? = [.macOS(.v15), .iOS(.v13)]
#else
let platforms: [PackageDescription.SupportedPlatform]? = nil
#endif

let package = Package(
    name: "BreezeLambdaDynamoDBAPI",
    platforms: platforms,
    products: [
        .library(
            name: "BreezeDynamoDBService",
            targets: ["BreezeDynamoDBService"]
        ),
        .library(
            name: "BreezeHTTPClientService",
            targets: ["BreezeHTTPClientService"]
        ),
        .library(
            name: "BreezeLambdaAPI",
            targets: ["BreezeLambdaAPI"]
        ),
        .executable(
            name: "BreezeDemoApplication",
            targets: ["BreezeDemoApplication"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", branch: "main"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", from: "0.5.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "7.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.2"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.24.0"),
    ],
    targets: [
        .executableTarget(
            name: "BreezeDemoApplication",
            dependencies: [
                "BreezeLambdaAPI"
            ]
        ),
        .target(
            name: "BreezeHTTPClientService",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "BreezeDynamoDBService",
            dependencies: [
                .product(name: "SotoDynamoDB", package: "soto"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                "BreezeHTTPClientService"
            ]
        ),
        .target(
            name: "BreezeLambdaAPI",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                "BreezeDynamoDBService"
            ]
        ),
        .testTarget(
            name: "BreezeLambdaAPITests",
            dependencies: [
                .product(name: "AWSLambdaTesting", package: "swift-aws-lambda-runtime"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "ServiceLifecycleTestKit", package: "swift-service-lifecycle"),
                "BreezeLambdaAPI"
            ],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "BreezeDynamoDBServiceTests",
            dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "ServiceLifecycleTestKit", package: "swift-service-lifecycle"),
                "BreezeDynamoDBService"
            ]
        ),
        .testTarget(
            name: "BreezeHTTPClientServiceTests",
            dependencies: [
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "ServiceLifecycleTestKit", package: "swift-service-lifecycle"),
                "BreezeHTTPClientService"
            ]
        )
    ]
)
