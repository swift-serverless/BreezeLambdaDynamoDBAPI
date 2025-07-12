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
import AsyncHTTPClient
import ServiceLifecycle
import Logging

/// BreezeDynamoDBServing
/// A protocol that defines the interface for a Breeze DynamoDB service.
/// It provides methods to access the database manager and to gracefully shutdown the service.
public protocol BreezeDynamoDBServing: Actor {
    func dbManager() async -> BreezeDynamoDBManaging
    func gracefulShutdown() throws
}

/// BreezeDynamoDBService is an actor that conforms to the BreezeDynamoDBServing protocol.
/// It provides methods to access the DynamoDB database manager and to gracefully shutdown the service.
public actor BreezeDynamoDBService: BreezeDynamoDBServing {
    
    private let dbManager: BreezeDynamoDBManaging
    private let logger: Logger
    private let awsClient: AWSClient
    private let httpClient: HTTPClient
    private var isShutdown = false
    
    /// Initializes the BreezeDynamoDBService with the provided configuration.
    /// - Parameters:
    ///   - config: The configuration for the DynamoDB service.
    ///   - httpConfig: The configuration for the HTTP client.
    ///   - logger: The logger to use for logging messages.
    ///   - DBManagingType: The type of the BreezeDynamoDBManaging to use. Defaults to BreezeDynamoDBManager.
    ///   This initializer sets up the AWS client, HTTP client, and the database manager.
    public init(
        config: BreezeDynamoDBConfig,
        httpConfig: BreezeHTTPClientConfig,
        logger: Logger,
        DBManagingType: BreezeDynamoDBManaging.Type = BreezeDynamoDBManager.self
    ) async {
        logger.info("Init DynamoDBService with config...")
        logger.info("region: \(config.region)")
        logger.info("tableName: \(config.tableName)")
        logger.info("keyName: \(config.keyName)")
        self.logger = logger
        
        let timeout = HTTPClient.Configuration.Timeout(
            connect: httpConfig.timeout,
            read: httpConfig.timeout
        )
        let configuration = HTTPClient.Configuration(timeout: timeout)
        self.httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: configuration
        )
        self.awsClient = AWSClient(httpClient: httpClient)
        let db = SotoDynamoDB.DynamoDB(
            client: awsClient,
            region: config.region,
            endpoint: config.endpoint
        )
        self.dbManager = DBManagingType.init(
            db: db,
            tableName: config.tableName,
            keyName: config.keyName
        )
        logger.info("DBManager is ready.")
    }
    
    /// Returns the BreezeDynamoDBManaging instance.
    public func dbManager() async -> BreezeDynamoDBManaging {
        logger.info("Starting DynamoDBService...")
        return self.dbManager
    }
    
    /// Gracefully shutdown the service and its components.
    /// - Throws: An error if the shutdown process fails.
    /// This method ensures that the AWS client and HTTP client are properly shutdown before marking the service as shutdown.
    /// It also logs the shutdown process.
    /// This method is idempotent;
    /// - Important: This method must be called at leat once to ensure that resources are released properly. If the method is not called, it will lead to a crash.
    public func gracefulShutdown() throws {
        guard !isShutdown else { return }
        isShutdown = true
        logger.info("Stopping DynamoDBService...")
        try awsClient.syncShutdown()
        logger.info("DynamoDBService is stopped.")
        logger.info("Stopping HTTPClient...")
        try httpClient.syncShutdown()
        logger.info("HTTPClient is stopped.")
    }
    
    deinit {
        guard !isShutdown else { return }
        try? awsClient.syncShutdown()
        try? httpClient.syncShutdown()
    }
}

