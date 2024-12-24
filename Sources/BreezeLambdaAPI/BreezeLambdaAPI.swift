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
import BreezeHTTPClientService
import AWSLambdaRuntime

public actor BreezeLambdaAPI<T: BreezeCodable>: Service {
    
    let logger = Logger(label: "service-group-breeze-lambda-api")
    let timeout: TimeAmount
    let httpClientService: BreezeHTTPClientServing
    let dynamoDBService: BreezeDynamoDBServing
    let breezeLambdaService: BreezeLambdaService<T>
    private let serviceGroup: ServiceGroup
    private let apiConfig: any APIConfiguring
    
    public init(apiConfig: APIConfiguring = BreezeAPIConfiguration()) throws {
        do {
            self.apiConfig = apiConfig
            self.timeout = .seconds(apiConfig.dbTimeout)
            self.httpClientService = BreezeHTTPClientService(
                timeout: timeout,
                logger: logger
            )
            let config = try apiConfig.getConfig()
            let serviceConfig = BreezeClientServiceConfig(
                httpClientService: httpClientService,
                logger: logger
            )
            self.dynamoDBService = BreezeDynamoDBService(config: config, serviceConfig: serviceConfig)
            self.breezeLambdaService = BreezeLambdaService<T>(
                dynamoDBService: dynamoDBService,
                operation: try apiConfig.operation(),
                logger: logger
            )
            self.serviceGroup = ServiceGroup(
                configuration: .init(
                    services: [
                        .init(
                            service: httpClientService,
                            successTerminationBehavior: .ignore,
                            failureTerminationBehavior: .gracefullyShutdownGroup
                        ),
                        .init(
                            service: dynamoDBService,
                            successTerminationBehavior: .gracefullyShutdownGroup,
                            failureTerminationBehavior: .gracefullyShutdownGroup
                        ),
                        .init(
                            service: breezeLambdaService,
                            successTerminationBehavior: .gracefullyShutdownGroup,
                            failureTerminationBehavior: .gracefullyShutdownGroup
                        )
                    ],
                    logger: logger
                )
            )
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }
    
    public func run() async throws {
        logger.info("Starting BreezeLambdaAPIService...")
        try await serviceGroup.run()
        logger.info("Stopping BreezeLambdaAPIService...")
        try await gracefulShutdown()
        logger.info("BreezeLambdaAPIService is stopped.")
    }
}
