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
import ServiceLifecycle
import BreezeHTTPClientService
import Logging

public protocol BreezeDynamoDBServing: Actor, Service {
    func dbManager() async -> BreezeDynamoDBManaging
}

public actor BreezeDynamoDBService: BreezeDynamoDBServing {
    
    private var _dbManager: BreezeDynamoDBManaging?
    private let config: BreezeDynamoDBConfig
    private let serviceConfig: BreezeClientServiceConfig
    private let DBManagingType: BreezeDynamoDBManaging.Type
    
    public func dbManager() async -> BreezeDynamoDBManaging {
        if let _dbManager {
            return _dbManager
        }
        let httpClient = await serviceConfig.httpClientService.httpClient
        let awsClient = AWSClient(httpClient: httpClient)
        self.awsClient = awsClient
        let db = SotoDynamoDB.DynamoDB(
            client: awsClient,
            region: config.region,
            endpoint: config.endpoint
        )
        let dbManager = DBManagingType.init(
            db: db,
            tableName: config.tableName,
            keyName: config.keyName
        )
        _dbManager = dbManager
        return dbManager
    }
    
    public init(
        config: BreezeDynamoDBConfig,
        serviceConfig: BreezeClientServiceConfig,
        DBManagingType: BreezeDynamoDBManaging.Type = BreezeDynamoDBManager.self
    ) {
        self.config = config
        self.serviceConfig = serviceConfig
        self.DBManagingType = DBManagingType
    }
    
    private var awsClient: AWSClient?
    
    private var logger: Logger {
        serviceConfig.logger
    }
    
    public func run() async throws {
        logger.info("Starting DynamoDBService...")
        logger.info("DynamoDBService is running with config...")
        logger.info("region: \(config.region)")
        logger.info("tableName: \(config.tableName)")
        logger.info("keyName: \(config.keyName)")
        
        try await gracefulShutdown()
        
        logger.info("Stopping DynamoDBService...")
        try await awsClient?.shutdown()
        self.awsClient = nil
        logger.info("DynamoDBService is stopped.")
    }
    
    deinit {
        try? awsClient?.syncShutdown()
    }
}

