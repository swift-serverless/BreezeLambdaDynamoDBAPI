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

import struct Foundation.Date
import NIO
import SotoDynamoDB

/// BreezeDynamoDBManager is a manager for handling DynamoDB operations in Breeze.
/// It provides methods to create, read, update, delete, and list items in a DynamoDB table.
/// It conforms to the BreezeDynamoDBManaging protocol, which defines the necessary operations for Breeze's DynamoDB integration.
/// - Note: This manager requires a DynamoDB instance, a table name, and a key name to operate.
/// It uses the SotoDynamoDB library to interact with AWS DynamoDB services.
public struct BreezeDynamoDBManager: BreezeDynamoDBManaging {
    
    /// ServiceError defines the possible errors that can occur when interacting with the BreezeDynamoDBManager.
    enum ServiceError: Error {
        /// Indicates that the requested item was not found in the DynamoDB table.
        case notFound
        /// Indicates that the operation failed due to missing parameters, such as a required key.
        case missingParameters
    }
    
    /// The name of the primary key in the DynamoDB table.
    public let keyName: String
    
    let db: DynamoDB
    let tableName: String

    /// Initializes a new instance of BreezeDynamoDBManager.
    /// - Parameters:
    ///   - db: The DynamoDB instance to use for operations.
    ///   - tableName: The name of the DynamoDB table to manage.
    ///   - keyName: The name of the primary key in the DynamoDB table.
    public init(db: DynamoDB, tableName: String, keyName: String) {
        self.db = db
        self.tableName = tableName
        self.keyName = keyName
    }
}

public extension BreezeDynamoDBManager {
    
    /// Creates a new item in the DynamoDB table.
    /// - Parameter item: The item to create, conforming to the BreezeCodable protocol.
    /// - Returns: The created item, with its `createdAt` and `updatedAt` timestamps set.
    func createItem<T: BreezeCodable>(item: T) async throws -> T {
        var item = item
        let date = Date()
        item.createdAt = date.iso8601
        item.updatedAt = date.iso8601
        let input = DynamoDB.PutItemCodableInput(
            conditionExpression: "attribute_not_exists(#keyName)",
            expressionAttributeNames: ["#keyName": keyName],
            item: item,
            tableName: tableName
        )
        let _ = try await db.putItem(input)
        return try await readItem(key: item.key)
    }

    /// Reads an item from the DynamoDB table by its key.
    /// - Parameter key: The key of the item to read.
    /// - Returns: The item with the specified key, conforming to the BreezeCodable protocol.
    func readItem<T: BreezeCodable>(key: String) async throws -> T {
        let input = DynamoDB.GetItemInput(
            key: [keyName: DynamoDB.AttributeValue.s(key)],
            tableName: tableName
        )
        let data = try await db.getItem(input, type: T.self)
        guard let item = data.item else {
            throw ServiceError.notFound
        }
        return item
    }

    private struct AdditionalAttributes: Encodable {
        let oldUpdatedAt: String
    }
    
    /// Updates an existing item in the DynamoDB table.
    /// - Parameter item: The item to update, conforming to the BreezeCodable protocol.
    /// - Returns: The updated item, with its `updatedAt` timestamp set to the current date.
    /// - Throws: An error if the item cannot be updated, such as if the item does not exist or the condition fails.
    /// - Important: The update operation checks that the `updatedAt` and `createdAt` timestamps match the existing values to prevent concurrent modifications.
    func updateItem<T: BreezeCodable>(item: T) async throws -> T {
        var item = item
        let oldUpdatedAt = item.updatedAt ?? ""
        let date = Date()
        item.updatedAt = date.iso8601
        let attributes = AdditionalAttributes(oldUpdatedAt: oldUpdatedAt)
        let input = try DynamoDB.UpdateItemCodableInput(
            additionalAttributes: attributes,
            conditionExpression: "attribute_exists(#\(keyName)) AND #updatedAt = :oldUpdatedAt AND #createdAt = :createdAt",
            key: [keyName],
            tableName: tableName,
            updateItem: item
        )
        let _ = try await db.updateItem(input)
        return try await readItem(key: item.key)
    }

    /// Deletes an item from the DynamoDB table.
    /// - Parameter item: The item to delete, conforming to the BreezeCodable protocol.
    /// - Throws: An error if the item cannot be deleted, such as if the item does not exist or the condition fails.
    /// - Important: The `updatedAt` and `createdAt` timestamps must be set on the item to ensure safe deletion. This method checks that the `updatedAt` and `createdAt` timestamps match the existing values to prevent concurrent modifications.
    func deleteItem<T: BreezeCodable>(item: T) async throws {
        guard let updatedAt = item.updatedAt,
              let createdAt = item.createdAt else {
            throw ServiceError.missingParameters
        }
        
        let input = DynamoDB.DeleteItemInput(
            conditionExpression: "#updatedAt = :updatedAt AND #createdAt = :createdAt",
            expressionAttributeNames: ["#updatedAt": "updatedAt",
                                       "#createdAt" : "createdAt"],
            expressionAttributeValues: [":updatedAt": .s(updatedAt),
                                        ":createdAt" : .s(createdAt)],
            key: [keyName: DynamoDB.AttributeValue.s(item.key)],
            tableName: tableName
        )
        let _ = try await db.deleteItem(input)
        return
    }

    /// Lists items in the DynamoDB table with optional pagination.
    /// - Parameters:
    /// - key: An optional key to start the listing from, useful for pagination.
    /// - limit: An optional limit on the number of items to return.
    /// - Returns: A `ListResponse` containing the items and the last evaluated key for pagination.
    /// - Throws: An error if the listing operation fails.
    /// - Important: The `key` parameter is used to continue listing from a specific point, and the `limit` parameter controls how many items are returned in one call.
    func listItems<T: BreezeCodable>(key: String?, limit: Int?) async throws -> ListResponse<T> {
        var exclusiveStartKey: [String: DynamoDB.AttributeValue]?
        if let key {
            exclusiveStartKey = [keyName: DynamoDB.AttributeValue.s(key)]
        }
        let input = DynamoDB.ScanInput(
            exclusiveStartKey: exclusiveStartKey,
            limit: limit,
            tableName: tableName
        )
        let data = try await db.scan(input, type: T.self)
        if let lastEvaluatedKeyShape = data.lastEvaluatedKey?[keyName],
           case .s(let lastEvaluatedKey) = lastEvaluatedKeyShape
        {
            return ListResponse(items: data.items ?? [], lastEvaluatedKey: lastEvaluatedKey)
        } else {
            return ListResponse(items: data.items ?? [], lastEvaluatedKey: nil)
        }
    }
}
