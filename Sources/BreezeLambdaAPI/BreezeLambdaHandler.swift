//    Copyright 2024 (c) Andrea Scuderi - https://github.com/swift-serverless
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

import AWSLambdaEvents
import AWSLambdaRuntime
import BreezeDynamoDBService
import Logging

/// Lambda handler implementing the followig operations: create, read, update, delete, and list.
///
/// Conforms to the `LambdaHandler` protocol and is generic over a type `T` that conforms to `BreezeCodable`.
/// Implements the logic for handling Breeze operations on a DynamoDB table by utilizing a `BreezeDynamoDBManaging` instance.
///
/// The handler supports the following operations:
///
/// - Create: Creates a new item in the DynamoDB table.
/// - Read: Reads an item from the DynamoDB table based on the provided key.
/// - Update: Updates an existing item in the DynamoDB table.
/// - Delete: Deletes an item from the DynamoDB table based on the provided key and timestamps.
/// - List: Lists items in the DynamoDB table with optional pagination.
struct BreezeLambdaHandler<T: BreezeCodable>: LambdaHandler, Sendable {
    typealias Event = APIGatewayV2Request
    typealias Output = APIGatewayV2Response

    let dbManager: BreezeDynamoDBManaging
    let operation: BreezeOperation

    var keyName: String {
        self.dbManager.keyName
    }
    
    /// Lambda handler for Breeze operations.
    /// - Parameters:
    ///  - event: The event containing the API Gateway request.
    ///  - context: The Lambda context providing information about the invocation.
    ///
    /// This initializer sets up the Breeze Lambda handler with the specified DynamoDB manager and operation.
    func handle(_ event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        switch self.operation {
        case .create:
            return await self.createLambdaHandler(context: context, event: event)
        case .read:
            return await self.readLambdaHandler(context: context, event: event)
        case .update:
            return await self.updateLambdaHandler(context: context, event: event)
        case .delete:
            return await self.deleteLambdaHandler(context: context, event: event)
        case .list:
            return await self.listLambdaHandler(context: context, event: event)
        }
    }

    /// Lambda handler for creating an item in the DynamoDB table.
    func createLambdaHandler(context: LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        guard let item: T = try? event.bodyObject() else {
            let error = BreezeLambdaAPIError.invalidRequest
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
        do {
            let result: T = try await dbManager.createItem(item: item)
            return APIGatewayV2Response(with: result, statusCode: .created)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
    }

    /// Lambda handler for reading an item from the DynamoDB table.
    func readLambdaHandler(context: LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        guard let key = event.pathParameters?[keyName] else {
            let error = BreezeLambdaAPIError.invalidRequest
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
        do {
            let result: T = try await dbManager.readItem(key: key)
            return APIGatewayV2Response(with: result, statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .notFound)
        }
    }

    /// Lambda handler for updating an item in the DynamoDB table.
    func updateLambdaHandler(context: LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        guard let item: T = try? event.bodyObject() else {
            let error = BreezeLambdaAPIError.invalidRequest
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
        do {
            let result: T = try await dbManager.updateItem(item: item)
            return APIGatewayV2Response(with: result, statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .notFound)
        }
    }
    
    struct SimpleItem: BreezeCodable {
        var key: String
        var createdAt: String?
        var updatedAt: String?
    }

    /// Lambda handler for deleting an item from the DynamoDB table.
    func deleteLambdaHandler(context: LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        guard let key = event.pathParameters?[keyName],
              let createdAt = event.queryStringParameters?["createdAt"],
              let updatedAt = event.queryStringParameters?["updatedAt"] else {
            let error = BreezeLambdaAPIError.invalidRequest
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
        do {
            let simpleItem = SimpleItem(key: key, createdAt: createdAt, updatedAt: updatedAt)
            try await self.dbManager.deleteItem(item: simpleItem)
            return APIGatewayV2Response(with: BreezeEmptyResponse(), statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .notFound)
        }
    }

    /// Lambda handler for listing items in the DynamoDB table.
    func listLambdaHandler(context: LambdaContext, event: APIGatewayV2Request) async -> APIGatewayV2Response {
        do {
            let key = event.queryStringParameters?["exclusiveStartKey"]
            let limit: Int? = event.queryStringParameterToInt("limit")
            let result: ListResponse<T> = try await dbManager.listItems(key: key, limit: limit)
            return APIGatewayV2Response(with: result, statusCode: .ok)
        } catch {
            return APIGatewayV2Response(with: error, statusCode: .forbidden)
        }
    }
}
