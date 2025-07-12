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

import SotoDynamoDB

/// BreezeDynamoDBManaging is a protocol that defines the methods for managing DynamoDB items.
public protocol BreezeDynamoDBManaging: Sendable {
    /// The keyName is the name of the primary key in the DynamoDB table.
    var keyName: String { get }
    /// Initializes the BreezeDynamoDBManaging with the provided DynamoDB client, table name, and key name.
    /// - Parameters:
    ///   - db: The DynamoDB client to use for database operations.
    ///   - tableName: The name of the DynamoDB table.
    ///   - keyName: The name of the primary key in the DynamoDB table.
    init(db: DynamoDB, tableName: String, keyName: String)
    
    /// Creates a new item in the DynamoDB table.
    /// - Parameter item: The item to create, conforming to BreezeCodable.
    /// - Returns: The created item.
    /// - Note:
    ///   - The item must conform to BreezeCodable.
    func createItem<Item: BreezeCodable>(item: Item) async throws -> Item
    
    /// Reads an item from the DynamoDB table.
    /// - Parameter key: The key of the item to read.
    /// - Returns: The item read from the table, conforming to BreezeCodable.
    /// - Throws: An error if the item could not be read.
    /// - Note:
    ///   - The key should match the primary key defined in the DynamoDB table.
    ///   - The item must conform to BreezeCodable.
    func readItem<Item: BreezeCodable>(key: String) async throws -> Item
    
    /// Updates an existing item in the DynamoDB table.
    /// - Parameter item: The item to update, conforming to BreezeCodable.
    /// - Returns: The updated item.
    /// - Throws: An error if the item could not be updated.
    /// - Note:
    ///   - The item must have the same primary key as an existing item in the table.
    ///   - The item must conform to BreezeCodable.
    func updateItem<Item: BreezeCodable>(item: Item) async throws -> Item
    
    /// Deletes an item from the DynamoDB table.
    /// - Parameter item: The item to delete, conforming to BreezeCodable.
    /// - Throws: An error if the item could not be deleted.
    /// - Returns: Void if the item was successfully deleted.
    /// - Note:
    ///   - The item must conform to BreezeCodable.
    ///   - The item must have the same primary key as an existing item in the table.
    func deleteItem<Item: BreezeCodable>(item: Item) async throws
    
    /// Lists items in the DynamoDB table.
    /// - Parameters:
    ///   - key: An optional key to filter the items.
    ///   - limit: An optional limit on the number of items to return.
    /// - Returns: A ListResponse containing the items and an optional last evaluated key.
    /// - Throws: An error if the items could not be listed.
    /// - Note:
    ///  - The items must conform to BreezeCodable.
    ///  - The key is used to filter the items based on the primary key defined in the DynamoDB table.
    ///  - The limit is used to control the number of items returned in the response.
    func listItems<Item: BreezeCodable>(key: String?, limit: Int?) async throws -> ListResponse<Item>
}
