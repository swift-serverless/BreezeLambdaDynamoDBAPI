# BreezeLambdaDynamoDBAPI
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-serverless%2Fhttps://app.codecov.io/gh/swift-serverless/BreezeLambdaDynamoDBAPI%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/swift-serverless/BreezeLambdaDynamoDBAPI) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswift-serverless%2FBreezeLambdaDynamoDBAPI%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/swift-serverless/BreezeLambdaDynamoDBAPI) ![Breeze CI](https://github.com/swift-serverless/BreezeLambdaDynamoDBAPI/actions/workflows/swift-test.yml/badge.svg) [![codecov](https://codecov.io/gh/swift-serverless/BreezeLambdaDynamoDBAPI/branch/main/graph/badge.svg?token=PJR7YGBSQ0)](https://codecov.io/gh/swift-serverless/BreezeLambdaDynamoDBAPI)

[![security status](https://www.meterian.io/badge/gh/swift-serverless/BreezeLambdaDynamoDBAPI/security?branch=main)](https://www.meterian.io/report/gh/swift-serverless/BreezeLambdaDynamoDBAPI)
[![stability status](https://www.meterian.io/badge/gh/swift-serverless/BreezeLambdaDynamoDBAPI/stability?branch=main)](https://www.meterian.io/report/gh/swift-serverless/BreezeLambdaDynamoDBAPI)
[![licensing status](https://www.meterian.io/badge/gh/swift-serverless/BreezeLambdaDynamoDBAPI/licensing?branch=main)](https://www.meterian.io/report/gh/swift-serverless/BreezeLambdaDynamoDBAPI)

![Breeze](logo.png)

## Usage

Add the dependency `BreezeLambdaDynamoDBAPI` to a package:

```swift
// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BreezeItemAPI",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "ItemAPI", targets: ["ItemAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-sprinter/BreezeLambdaDynamoDBAPI.git", from: "0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "ItemAPI",
             dependencies: [
                .product(name: "BreezeLambdaAPI", package: "Breeze"),
                .product(name: "BreezeDynamoDBService", package: "Breeze"),
            ]
        )
    ]
)
```

Add a `Codable` `struct` entity conformed to the `BreezeCodable` protocol:

```swift
import Foundation
import BreezeLambdaAPI
import BreezeDynamoDBService

struct Item: Codable {
    public var key: String
    public let name: String
    public let description: String
    public var createdAt: String?
    public var updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case key = "itemKey"
        case name
        case description
        case createdAt
        case updatedAt
    }
}

extension Item: BreezeCodable { }
```

Add the implementation of the Lambda to the file `swift.main`

```swift
BreezeLambdaAPI<Item>.main()
```

## Documentation

Refer to the main project https://github.com/swift-serverless/Breeze for more info and working examples.

## Contributing

Contributions are welcome! If you encounter any issues or have ideas for improvements, please open an issue or submit a pull request.



