// swift-tools-version: 6.0

import PackageDescription

#if os(macOS)
let platforms: [PackageDescription.SupportedPlatform]? = [.macOS(.v15)]
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
            name: "BreezeLambdaAPI",
            targets: ["BreezeLambdaAPI"]
        ),
        .executable(
            name: "BreezeLambdaItemAPI",
            targets: ["BreezeLambdaItemAPI"]
        )
    ],
    dependencies: [
        // TODO: change to upstream once the upstream is tagged
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "2.0.0-beta.1"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", from: "0.5.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.0.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "7.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.2"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "BreezeLambdaItemAPI",
            dependencies: [
                "BreezeLambdaAPI"
            ]
        ),
        .target(
            name: "BreezeDynamoDBService",
            dependencies: [
                .product(name: "SotoDynamoDB", package: "soto"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
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
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
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
        )
    ]
)
