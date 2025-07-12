# BreezeLambdaAPI

@Metadata {
   @PageImage(purpose: icon, source: "Icon")
}

## Essentials

Add the dependency `BreezeLambdaDynamoDBAPI` to a package:

```swift
// swift-tools-version:6.1
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
@main
struct BreezeLambdaItemAPI {
    static func main() async throws {
      do {
            try await BreezeLambdaAPI<Item>().run()
        } catch {
            print(error.localizedDescription)
        }
    }
}
```

## Deployment

Refer to the main project https://github.com/swift-serverless/Breeze for more info on how to deploy it on AWS.




