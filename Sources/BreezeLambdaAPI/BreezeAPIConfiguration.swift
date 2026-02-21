//
//  BreezeAPIConfiguration.swift
//  BreezeLambdaDynamoDBAPI
//
//  Created by Andrea Scuderi on 24/12/2024.
//

import SotoDynamoDB
import BreezeDynamoDBService
import Configuration

/// Defines the configuration for the Breeze Lambda API.
public protocol APIConfiguring: Sendable {
    var dbTimeout: Int64 { get }
    func operation() throws -> BreezeOperation
    func getConfig() throws -> BreezeDynamoDBConfig
}

/// A struct that conforms to APIConfiguring protocol, providing essential configuration for Lambda functions that interact with DynamoDB.
///
/// It fetches the necessary configuration from environment variables, such as the Handler, AWS region, DynamoDB table name, and key name.
///
/// To configure the Lambda function, you need to set up the following environment variables:
/// - `_HANDLER`: The handler for the Lambda function, in the format `module.operation`.
/// - `AWS_REGION`: The AWS region where the DynamoDB table is located.
/// - `DYNAMO_DB_TABLE_NAME`: The name of the DynamoDB table.
/// - `DYNAMO_DB_KEY`: The name of the primary key in the DynamoDB table.
public struct BreezeAPIConfiguration: APIConfiguring {
    private enum Keys {
        static let handler: ConfigKey = "_HANDLER"
        static let awsRegion: ConfigKey = "AWS_REGION"
        static let tableName: ConfigKey = "DYNAMO_DB_TABLE_NAME"
        static let keyName: ConfigKey = "DYNAMO_DB_KEY"
        static let localstackEndpoint: ConfigKey = "LOCALSTACK_ENDPOINT"
        static let dbTimeout: ConfigKey = "BREEZE_DB_TIMEOUT"
    }
    
    private let reader: ConfigReader
    
    /// Creates the configuration using the supplied providers. Defaults to environment variables.
    public init(
        reader: ConfigReader = ConfigReader(
            providers: [EnvironmentVariablesProvider()]
        )
    ) {
        self.reader = reader
    }
    
    /// Timeout for database operations in seconds, configurable via `BREEZE_DB_TIMEOUT`.
    public var dbTimeout: Int64 {
        Int64(reader.int(forKey: Keys.dbTimeout, default: 30))
    }
    
    /// The operation handler for Breeze operations.
    ///
    /// Resturns the operation that will be executed by the Breeze Lambda API.
    /// This method retrieves the handler from the environment variable `_HANDLER`.
    /// - Throws: `BreezeLambdaAPIError.invalidHandler` if the handler is not found or cannot be parsed.
    /// - Returns: A `BreezeOperation` instance initialized with the handler.
    ///
    /// - Note: It expects the `_HANDLER` environment variable to be set in the format `module.operation`.
    ///
    ///  See BreezeOperation for more details.
    public func operation() throws -> BreezeOperation {
        guard let handler = reader.string(forKey: Keys.handler),
              let operation = BreezeOperation(handler: handler)
        else {
            throw BreezeLambdaAPIError.invalidHandler
        }
        return operation
    }
    
    /// Gets the configuration from the process environment.
    ///
    /// - Throws:
    ///   - `BreezeLambdaAPIError.tableNameNotFound` if the DynamoDB table name is not found in the environment variables.
    ///   - `BreezeLambdaAPIError.keyNameNotFound` if the DynamoDB key name is not found in the environment variables.
    /// - Returns: A `BreezeDynamoDBConfig` instance containing the configuration for the Breeze DynamoDB service.
    /// This method is used to retrieve the necessary configuration for the Breeze Lambda API to interact with DynamoDB.
    /// It includes the AWS region, DynamoDB table name, key name, and an optional endpoint for LocalStack.
    /// - Important: The configuration is essential for the Breeze Lambda API to function correctly with DynamoDB. This method retrieves the configuration from environment variables:
    ///   - `AWS_REGION`: The AWS region where the DynamoDB table is located.
    ///   - `DYNAMO_DB_TABLE_NAME`: The name of the DynamoDB table.
    ///   - `DYNAMO_DB_KEY`: The name of the primary key in the DynamoDB table.
    public func getConfig() throws -> BreezeDynamoDBConfig {
        BreezeDynamoDBConfig(
            region: currentRegion(),
            tableName: try tableName(),
            keyName: try keyName(),
            endpoint: endpoint()
        )
    }
    
    /// Returns the current AWS region based on the `AWS_REGION` environment variable.
    /// If the variable is not set, it defaults to `.useast1`.
    /// - Returns: A `Region` instance representing the current AWS region.
    ///
    /// This method is used to determine the AWS region where the DynamoDB table is located.
    func currentRegion() -> Region {
        if let awsRegion = reader.string(forKey: Keys.awsRegion) {
            return Region(rawValue: awsRegion)
        }
        return .useast1
    }
    
    /// Returns the DynamoDB table name from the `DYNAMO_DB_TABLE_NAME` environment variable.
    /// - Throws: `BreezeLambdaAPIError.tableNameNotFound` if the table name is not found in the environment variables.
    /// - Returns: A `String` representing the DynamoDB table name.
    /// This method is used to retrieve the name of the DynamoDB table that will be used by the Breeze Lambda API.
    /// - Important: The table name is essential for performing operations on the DynamoDB table.
    func tableName() throws -> String {
        guard let tableName = reader.string(forKey: Keys.tableName) else {
            throw BreezeLambdaAPIError.tableNameNotFound
        }
        return tableName
    }
    
    /// Returns the DynamoDB key name from the `DYNAMO_DB_KEY` environment variable.
    /// - Throws: `BreezeLambdaAPIError.keyNameNotFound` if the key name is not found in the environment variables.
    /// - Returns: A `String` representing the DynamoDB key name.
    /// This method is used to retrieve the name of the primary key in the DynamoDB table that will be used by the Breeze Lambda API.
    /// - Important: The key name is essential for identifying items in the DynamoDB table.
    func keyName() throws -> String {
        guard let keyName = reader.string(forKey: Keys.keyName) else {
            throw BreezeLambdaAPIError.keyNameNotFound
        }
        return keyName
    }
    
    /// Returns the endpoint for the Breeze Lambda API.
    /// If the `LOCALSTACK_ENDPOINT` environment variable is set, it returns that value.
    /// - Returns: An optional `String` representing the endpoint URL.
    /// - Important: If the `LOCALSTACK_ENDPOINT` environment variable is not set, it returns `nil`, indicating that no custom endpoint is configured.
    /// - Note:
    ///   - This method is useful for testing purposes, especially when running the Breeze Lambda API locally with LocalStack.
    ///   - LocalStack is a fully functional local AWS cloud stack that allows you to test AWS services locally.
    ///   - To set it you need to set the `LOCALSTACK_ENDPOINT` environment variable to the URL of your LocalStack instance.
    ///   - The Default LocalStack endpoint is `http://localhost:4566`
    func endpoint() -> String? {
        if let localstack = reader.string(forKey: Keys.localstackEndpoint),
           !localstack.isEmpty {
            return localstack
        }
        return nil
    }
}
