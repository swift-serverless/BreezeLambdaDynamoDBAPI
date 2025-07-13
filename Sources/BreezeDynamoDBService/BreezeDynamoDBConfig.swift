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

/// Configuration structure for Breeze DynamoDB service.
///
/// BreezeDynamoDBConfig contains the necessary parameters to connect to a DynamoDB instance, including the region, table name, key name, and an optional endpoint.
public struct BreezeDynamoDBConfig: Sendable {
    
    /// Initializes a new instance of BreezeDynamoDBConfig.
    /// - Parameters:
    ///   - region: The AWS region where the DynamoDB table is located.
    ///   - tableName: The name of the DynamoDB table.
    ///   - keyName: The name of the primary key in the DynamoDB table.
    ///   - endpoint: An optional endpoint URL for the DynamoDB service. If not provided, the default AWS endpoint will be used.
    public init(
        region: Region,
        tableName: String,
        keyName: String,
        endpoint: String? = nil
    ) {
        self.region = region
        self.tableName = tableName
        self.keyName = keyName
        self.endpoint = endpoint
    }
    
    /// The AWS region where the DynamoDB table is located.
    public let region: Region
    
    /// The name of the DynamoDB table.
    public let tableName: String
    
    /// The name of the primary key in the DynamoDB table.
    public let keyName: String
    
    /// An optional endpoint URL for the DynamoDB service.
    public let endpoint: String?
}
