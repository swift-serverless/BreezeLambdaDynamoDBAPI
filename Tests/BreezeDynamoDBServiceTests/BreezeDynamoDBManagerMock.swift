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

import BreezeDynamoDBService
import SotoDynamoDB

actor BreezeDynamoDBManagerMock: BreezeDynamoDBManaging {
    let keyName: String
    
    enum BreezeDynamoDBManagerError: Error {
        case invalidRequest
        case invalidItem
    }
    
    private var response: (any BreezeCodable)?
    private var keyedResponse: (any BreezeCodable)?
    
    func setupMockResponse(response: (any BreezeCodable)?, keyedResponse: (any BreezeCodable)?) {
        self.keyedResponse = keyedResponse
        self.response = response
    }
    
    init(db: SotoDynamoDB.DynamoDB, tableName: String, keyName: String) {
        self.keyName = keyName
    }
    
    func createItem<T: BreezeCodable>(item: T) async throws -> T {
        guard let response = self.response as? T else {
            throw BreezeDynamoDBManagerError.invalidRequest
        }
        return response
    }
    
    func readItem<T: BreezeCodable>(key: String) async throws -> T {
        guard let response = self.keyedResponse as? T,
              response.key == key
        else {
            throw BreezeDynamoDBManagerError.invalidRequest
        }
        return response
    }
    
    func updateItem<T: BreezeCodable>(item: T) async throws -> T {
        guard let response = self.keyedResponse as? T,
              response.key == item.key
        else {
            throw BreezeDynamoDBManagerError.invalidRequest
        }
        return response
    }
    
    func deleteItem<T: BreezeCodable>(item: T) async throws {
        guard let response = self.keyedResponse,
              response.key == item.key,
              response.createdAt == item.createdAt,
              response.updatedAt == item.updatedAt
        else {
            throw BreezeDynamoDBManagerError.invalidRequest
        }
        return
    }
    
    var limit: Int?
    var exclusiveKey: String?
    func listItems<T: BreezeCodable>(key: String?, limit: Int?) async throws -> ListResponse<T> {
        guard let response = self.response as? T else {
            throw BreezeDynamoDBManagerError.invalidItem
        }
        self.limit = limit
        self.exclusiveKey = key
        return ListResponse(items: [response], lastEvaluatedKey: key)
    }
}
