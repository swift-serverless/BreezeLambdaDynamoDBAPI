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

import SotoCore
import SotoDynamoDB
import Testing
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
@testable import BreezeDynamoDBService

struct Product: BreezeCodable {
    var key: String
    var name: String
    var description: String
    var createdAt: String?
    var updatedAt: String?
}

@Suite
struct BreezeDynamoDBManagerTests {
    
    let keyName = "key"
    
    let product2023 = Product(key: "2023", name: "Swift Serverless API 2022", description: "Test")
    let product2022 = Product(key: "2022", name: "Swift Serverless API with async/await! 🚀🥳", description: "BreezeLambaAPI is magic 🪄!")
    
    func givenTable(tableName: String) async throws -> BreezeDynamoDBManager {
        try await LocalStackDynamoDB.createTable(name: tableName, keyName: keyName)
        let db = LocalStackDynamoDB.dynamoDB
        return BreezeDynamoDBManager(db: db, tableName: tableName, keyName: keyName)
    }
    
    func removeTable(tableName: String) async throws {
        try await LocalStackDynamoDB.deleteTable(name: tableName)
    }
    
    @Test
    func test_createItem() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        let value = try await sut.createItem(item: product2023)
        #expect(value.key == product2023.key)
        #expect(value.name == product2023.name)
        #expect(value.description == product2023.description)
        try #require(value.createdAt?.iso8601 != nil)
        try #require(value.updatedAt?.iso8601 != nil)
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_createItemDuplicate_shouldThrowConditionalCheckFailedException() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        let value = try await sut.createItem(item: product2023)
        #expect(value.key == product2023.key)
        #expect(value.name == product2023.name)
        #expect(value.description == product2023.description)
        try #require(value.createdAt?.iso8601 != nil)
        try #require(value.updatedAt?.iso8601 != nil)
        do {
            _ = try await sut.createItem(item: product2023)
            Issue.record("It should throw DynamoDBErrorType.conditionalCheckFailedException")
        } catch {
            let dynamoDBError = try #require(error as? DynamoDBErrorType)
            #expect(dynamoDBError == .conditionalCheckFailedException)
        }
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_readItem() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        let cretedItem = try await sut.createItem(item: product2023)
        let readedItem: Product = try await sut.readItem(key: "2023")
        #expect(cretedItem.key == readedItem.key)
        #expect(cretedItem.name == readedItem.name)
        #expect(cretedItem.description == readedItem.description)
        #expect(cretedItem.createdAt?.iso8601 == readedItem.createdAt?.iso8601)
        #expect(cretedItem.updatedAt?.iso8601 == readedItem.updatedAt?.iso8601)
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_readItem_whenItemIsMissing() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        let value = try await sut.createItem(item: product2023)
        #expect(value.key == "2023")
        do {
            let _: Product = try await sut.readItem(key: "2022")
            Issue.record("It should throw ServiceError.notfound when Item is missing")
        } catch {
            let dynamoDBError = try #require(error as? BreezeDynamoDBManager.ServiceError)
            #expect(dynamoDBError == .notFound)
        }
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_updateItem() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        var value = try await sut.createItem(item: product2023)
        value.name = "New Name"
        value.description = "New Description"
        let newValue = try await sut.updateItem(item: value)
        #expect(value.key == newValue.key)
        #expect(value.name == newValue.name)
        #expect(value.description == newValue.description)
        #expect(value.createdAt?.iso8601 == newValue.createdAt?.iso8601)
        #expect(value.updatedAt?.iso8601 != newValue.updatedAt?.iso8601)
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_updateItem_whenItemHasChanged_shouldThrowConditionalCheckFailedException() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        var value = try await sut.createItem(item: product2023)
        value.name = "New Name"
        value.description = "New Description"
        let newValue = try await sut.updateItem(item: value)
        #expect(value.key == newValue.key)
        #expect(value.name == newValue.name)
        #expect(value.description == newValue.description)
        #expect(value.createdAt?.iso8601 == newValue.createdAt?.iso8601)
        #expect(value.updatedAt?.iso8601 != newValue.updatedAt?.iso8601)
        do {
            let _: Product = try await sut.updateItem(item: product2023)
            Issue.record("It should throw AWSResponseError ValidationException")
        } catch {
            let dynamoDBError = try #require(error as? AWSResponseError)
            #expect(dynamoDBError.errorCode == "ValidationException")
        }
        
        do {
            let _: Product = try await sut.updateItem(item: product2022)
            Issue.record("It should throw AWSResponseError ValidationException")
        } catch {
            let dynamoDBError = try #require(error as? AWSResponseError)
            #expect(dynamoDBError.errorCode == "ValidationException")
        }
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_deleteItem() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        let value = try await sut.createItem(item: product2023)
        #expect(value.key == "2023")
        try await sut.deleteItem(item: value)
        let readedItem: Product? = try? await sut.readItem(key: "2023")
        #expect(readedItem == nil)
        try await removeTable(tableName: uuid)
    }
    
    func test_deleteItem_whenItemIsMissing_thenShouldThrow() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        do {
            try await sut.deleteItem(item: product2022)
            Issue.record("It should throw DynamoDBErrorType.conditionalCheckFailedException")
        } catch {
            let dynamoDBError = try #require(error as? DynamoDBErrorType)
            #expect(dynamoDBError == .conditionalCheckFailedException)
        }
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_deleteItem_whenMissingUpdatedAt_thenShouldThrow() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        var value = try await sut.createItem(item: product2023)
        #expect(value.key == "2023")
        value.updatedAt = nil
        do {
            try await sut.deleteItem(item: value)
            Issue.record("It should throw ServiceError.missingParameters")
        } catch {
            let dynamoDBError = try #require(error as? BreezeDynamoDBManager.ServiceError)
            #expect(dynamoDBError == .missingParameters)
        }
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_deleteItem_whenMissingCreatedAt_thenShouldThrow() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        var value = try await sut.createItem(item: product2023)
        #expect(value.key == "2023")
        value.createdAt = nil
        do {
            try await sut.deleteItem(item: value)
            Issue.record("It should throw ServiceError.missingParameters")
        } catch {
            let dynamoDBError = try #require(error as? BreezeDynamoDBManager.ServiceError)
            #expect(dynamoDBError == .missingParameters)
        }
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_deleteItem_whenOutdatedUpdatedAt_thenShouldThrow() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        var value = try await sut.createItem(item: product2023)
        #expect(value.key == "2023")
        value.updatedAt = Date().iso8601
        do {
            try await sut.deleteItem(item: value)
            Issue.record("It should throw DynamoDBErrorType.conditionalCheckFailedException")
        } catch {
            let dynamoDBError = try #require(error as? DynamoDBErrorType)
            #expect(dynamoDBError == .conditionalCheckFailedException)
        }
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_deleteItem_whenOutdatedCreatedAt_thenShouldThrow() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        var value = try await sut.createItem(item: product2023)
        #expect(value.key == "2023")
        value.createdAt = Date().iso8601
        do {
            try await sut.deleteItem(item: value)
            Issue.record("It should throw DynamoDBErrorType.conditionalCheckFailedException")
        } catch {
            let dynamoDBError = try #require(error as? DynamoDBErrorType)
            #expect(dynamoDBError == .conditionalCheckFailedException)
        }
        try await removeTable(tableName: uuid)
    }
    
    @Test
    func test_listItem() async throws {
        let uuid = UUID().uuidString
        let sut = try await givenTable(tableName: uuid)
        let value1 = try await sut.createItem(item: product2022)
        let value2 = try await sut.createItem(item: product2023)
        let list: ListResponse<Product> = try await sut.listItems(key: nil, limit: nil)
        #expect(list.items.count == 2)
        let keys = Set(list.items.map { $0.key })
        #expect(keys.contains(value1.key))
        #expect(keys.contains(value2.key))
        try await removeTable(tableName: uuid)
    }
}
