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

/// Protocol that combines Sendable and Codable.
public protocol CodableSendable: Sendable, Codable { }

/// Protocol that extends CodableSendable to include properties
/// for a key, creation date, and update date.
///
/// BreezeCodable is designed to be used with Breeze services that require these common fields
/// for items stored in a database, such as DynamoDB.
/// - Parameters:
///   - key: A unique identifier for the item.
///   - createdAt: An optional string representing the creation date of the item.
///   - updatedAt: An optional string representing the last update date of the item.
public protocol BreezeCodable: CodableSendable {
    var key: String { get set }
    var createdAt: String? { get set }
    var updatedAt: String? { get set }
}
