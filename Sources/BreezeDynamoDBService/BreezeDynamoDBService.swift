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

/// Defines the interface for a Breeze DynamoDB service.
/// 
/// Provides methods to access the database manager and to gracefully shutdown the service.
public protocol BreezeDynamoDBServing: Service {
    var dbManager: BreezeDynamoDBManaging { get }
    func onGracefulShutdown() async throws
    func syncShutdown() throws
}

/// Provides methods to access the DynamoDB database manager and to gracefully shutdown the service.
public struct BreezeDynamoDBService: BreezeDynamoDBServing {
    
    public let dbManager: BreezeDynamoDBManaging
    private let logger: Logger
    private let awsClient: AWSClient
    private let httpClient: HTTPClient
    private let shutdownState: ShutdownState

    /// Error types for BreezeDynamoDBService
    enum BreezeDynamoDBServiceError: Error {
        case alreadyShutdown
    }

    /// Actor to manage shutdown state safely
    private actor ShutdownState {
        private var isShutdown = false
        
        func markShutdown() throws {
            guard !isShutdown else {
                throw BreezeDynamoDBServiceError.alreadyShutdown
            }
            isShutdown = true
        }
    }
        
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
    ) {
        logger.info("Init DynamoDBService with config...")
        logger.info("region: \(config.region)")
        logger.info("tableName: \(config.tableName)")
        logger.info("keyName: \(config.keyName)")
        if config.endpoint != nil {
            logger.info("endpoint: \(config.endpoint!)")
        }
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
        self.shutdownState = ShutdownState()
        logger.info("DBManager is ready.")
    }
    
    public func run() async throws {
        try await gracefulShutdown()
        try await onGracefulShutdown()
    }
    
    /// Gracefully shutdown the service and its components.
    ///
    /// - Throws: An error if the shutdown process fails.
    /// This method ensures that the AWS client and HTTP client are properly shutdown before marking the service as shutdown.
    /// It also logs the shutdown process.
    /// This method is idempotent and will throw if called multiple times to prevent double shutdown.
    /// - Important: This method must be called at least once to ensure that resources are released properly. If the method is not called, it will lead to a crash.
    public func onGracefulShutdown() async throws {
        try await shutdownState.markShutdown()
        logger.info("Stopping DynamoDBService...")
        try await awsClient.shutdown()
        logger.info("DynamoDBService is stopped.")
        logger.info("Stopping HTTPClient...")
        try await httpClient.shutdown()
        logger.info("HTTPClient is stopped.")
    }
    
    /// Sync shutdown
    public func syncShutdown() throws {
        try awsClient.syncShutdown()
        try httpClient.syncShutdown()
    }
}

