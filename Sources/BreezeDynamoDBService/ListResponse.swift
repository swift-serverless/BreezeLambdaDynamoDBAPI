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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Model representing a paginated list response from a DynamoDB operation.
/// This struct contains an array of items and an optional last evaluated key for pagination.
/// This struct conforms to `CodableSendable`, allowing it to be encoded and decoded for network transmission or storage.
public struct ListResponse<Item: CodableSendable>: CodableSendable {
    
    /// Initializes a new instance of `ListResponse`.
    /// - Parameters:
    ///   - items: An array of items returned from the DynamoDB operation.
    ///   - lastEvaluatedKey: An optional string representing the last evaluated key for pagination. If nil, it indicates that there are no more items to fetch.
    ///
    /// This initializer is used to create a paginated response for DynamoDB operations.
    public init(items: [Item], lastEvaluatedKey: String? = nil) {
        self.items = items
        self.lastEvaluatedKey = lastEvaluatedKey
    }
    
    /// The items returned from the DynamoDB operation.
    public let items: [Item]
    
    /// An optional string representing the last evaluated key for pagination.
    public let lastEvaluatedKey: String?
}
