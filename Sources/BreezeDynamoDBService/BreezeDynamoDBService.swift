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

public protocol BreezeDynamoDBServing: Actor {
    func dbManager() async -> BreezeDynamoDBManaging
    func gracefulShutdown() throws
}

public actor BreezeDynamoDBService: BreezeDynamoDBServing {
    
    private let dbManager: BreezeDynamoDBManaging
    private let config: BreezeDynamoDBConfig
    private let httpConfig: BreezeHTTPClientConfig
    private let logger: Logger
    private let DBManagingType: BreezeDynamoDBManaging.Type
    private var awsClient: AWSClient
    private let httpClient: HTTPClient
    
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
        
        self.config = config
        self.httpConfig = httpConfig
        self.logger = logger
        self.DBManagingType = DBManagingType
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
    
    public func dbManager() async -> BreezeDynamoDBManaging {
        self.dbManager
    }
    
    public func gracefulShutdown() throws {
        logger.info("Stopping DynamoDBService...")
        try awsClient.syncShutdown()
        logger.info("DynamoDBService is stopped.")
        logger.info("Stopping HTTPClient...")
        try httpClient.syncShutdown()
        logger.info("HTTPClient is stopped.")
    }
}

