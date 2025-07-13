# ``BreezeLambdaAPI``

@Metadata { 
   @PageImage(purpose: icon, source: "Icon")
   @PageImage(purpose: card, source: "Icon")
}

## Overview

The BreezeLambdaAPI implements a Lambda which processes events from AWS API Gateway and performs CRUD operations on AWS DynamoDB, allowing you to build serverless applications with ease.

### Key Features

- Serverless Architecture: Runs on AWS Lambda with API Gateway integration
- DynamoDB Integration: Seamless CRUD operations with DynamoDB
- Optimistic Concurrency Control: Ensures data integrity during updates and deletes
- Type Safety: Leverages Swift's type system with Codable support
- Swift Concurrency: Fully compatible with Swift's async/await model
- Service Lifecycle: Handles graceful shutdown and initialization of services
- Minimal Boilerplate: Focus on your business logic, not infrastructure code

### API Operations

- **Create**: Add new items to DynamoDB with automatic timestamp handling
- **Read**: Retrieve items using a unique key
- **Update**: Modify existing items with optimistic concurrency control
- **Delete**: Remove items with concurrency checks
- **List**: Retrieve all items with optional pagination

### The BreezeCodable Protocol

Your data models must conform to the `BreezeCodable` protocol, which extends `Codable` and provides additional properties for managing timestamps and keys.

```swift
public protocol BreezeCodable: Codable, Sendable {
    var key: String { get set }
    var createdAt: String? { get set }
    var updatedAt: String? { get set }
}
```

## Getting Started

### Add the dependency

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

### Define Your Data Model

Create a `Codable` struct that conforms to the `BreezeCodable` protocol. This struct will represent the items you want to store in DynamoDB.

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

### Implement the Lambda Handler

Create a file named `main.swift` and implement the Lambda handler using the `BreezeLambdaAPI` class.

This simple runner will handle the CRUD operations for your `Item` model.

Once compiled, this will be your Lambda function and must be deployed to AWS Lambda.

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

### Configure the Lambda

To configure the Lambda function, you need to set up the following environment variables:
- `_HANDLER`: The handler for the Lambda function, in the format `module.operation`.
- `AWS_REGION`: The AWS region where the DynamoDB table is located.
- `DYNAMO_DB_TABLE_NAME`: The name of the DynamoDB table.
- `DYNAMO_DB_KEY`: The name of the primary key in the DynamoDB table.

## Deployment

Deploy your Lambda function using AWS CDK, SAM, Serverless or Terraform. The Lambda requires:

1. API Gateway integration for HTTP requests
2. DynamoDB table with appropriate permissions
3. Environment variables for configuration

For step-by-step deployment instructions and templates, see the [Breeze project repository](https://github.com/swift-serverless/Breeze) for more info on how to deploy it on AWS.




