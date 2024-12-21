//    Copyright 2023 (c) Andrea Scuderi - https://github.com/swift-serverless
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

public extension BreezeDynamoDBService {
    enum DynamoDB {
        public static let Service: BreezeDynamoDBManaging.Type = BreezeDynamoDBManager.self
    }
}

public actor BreezeDynamoDBService: Service {
    
    public struct Config: Sendable {
        
        let httpClientService: BreezeHTTPClientService
        let region: Region
        let tableName: String
        let keyName: String
        let logger: Logger
        
        public init(httpClientService: BreezeHTTPClientService, region: Region, tableName: String, keyName: String, logger: Logger) {
            self.httpClientService = httpClientService
            self.region = region
            self.tableName = tableName
            self.keyName = keyName
            self.logger = logger
        }
    }

    public var dbManager: BreezeDynamoDBManaging?
    private var awsClient: AWSClient?
    private let config: Config
    
    public init(with config: Config) {
        self.config = config
    }
    
    public func run() async throws {
        config.logger.info("Starting DynamoDBService...")
        let httpClient = await config.httpClientService.httpClient
        let awsClient = AWSClient(httpClientProvider: .shared(httpClient))
        let db = SotoDynamoDB.DynamoDB(client: awsClient, region: config.region)
        
        self.dbManager = DynamoDB.Service.init(
            db: db,
            tableName: config.tableName,
            keyName: config.keyName
        )
        config.logger.info("DynamoDBService config...")
        config.logger.info("region: \(config.region)")
        config.logger.info("tableName: \(config.tableName)")
        config.logger.info("keyName: \(config.keyName)")
        
        try await gracefulShutdown()
        
        config.logger.info("Shutting down DynamoDBService...")
        try self.awsClient?.syncShutdown()
    }
}

