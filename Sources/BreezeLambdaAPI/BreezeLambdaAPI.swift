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
import BreezeDynamoDBService
import AWSLambdaRuntime

public actor BreezeLambdaAPI<T: BreezeCodable>: Service {
    
    let logger = Logger(label: "service-group-breeze-lambda-api")
    let timeout: TimeAmount
    private let serviceGroup: ServiceGroup
    private let apiConfig: any APIConfiguring
    
    public init(apiConfig: APIConfiguring = BreezeAPIConfiguration()) async throws {
        do {
            self.apiConfig = apiConfig
            self.timeout = .seconds(apiConfig.dbTimeout)
            let config = try apiConfig.getConfig()
            let httpConfig = BreezeHTTPClientConfig(
                timeout: .seconds(60),
                logger: logger
            )
            let dynamoDBService = await BreezeDynamoDBService(
                config: config,
                httpConfig: httpConfig,
                logger: logger
            )
            let breezeLambdaService = BreezeLambdaService<T>(
                dynamoDBService: dynamoDBService,
                operation: try apiConfig.operation(),
                logger: logger
            )
            self.serviceGroup = ServiceGroup(
                services: [breezeLambdaService],
                gracefulShutdownSignals: [.sigterm, .sigint],
                logger: logger
            )
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }
    
    public func run() async throws {
        logger.info("Starting BreezeLambdaAPI...")
        try await serviceGroup.run()
        logger.info("BreezeLambdaAPI is stopped successfully")
    }
}
