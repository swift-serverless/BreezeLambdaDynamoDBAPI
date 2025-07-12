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

/// BreezeLambdaAPIError is an enumeration that defines various errors that can occur in the Breeze Lambda API.
enum BreezeLambdaAPIError: Error {
    /// Indicates that an item is invalid.
    case invalidItem
    /// Indicates that the DynamoDB table name is not found in the environment.
    case tableNameNotFound
    /// Indicates that the key name for the DynamoDB table is not found in the environment.
    case keyNameNotFound
    /// Indicates that the request made to the API is invalid.
    case invalidRequest
    /// Indicates that the _HANDLER environment variable is invalid or missing.
    case invalidHandler
    /// Indicates that the service is invalid, possibly due to misconfiguration or an unsupported operation.
    case invalidService
}

/// Extension for BreezeLambdaAPIError to provide localized error descriptions.
extension BreezeLambdaAPIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidItem:
            return "Invalid Item"
        case .tableNameNotFound:
            return "Environment DYNAMO_DB_TABLE_NAME is not set"
        case .keyNameNotFound:
            return "Environment DYNAMO_DB_KEY is not set"
        case .invalidRequest:
            return "Invalid request"
        case .invalidHandler:
            return "Environment _HANDLER is invalid or missing"
        case .invalidService:
            return "Invalid Service"
        }
    }
}
