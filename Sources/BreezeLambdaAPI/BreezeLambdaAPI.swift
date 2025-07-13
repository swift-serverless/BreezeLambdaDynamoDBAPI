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

/// BreezeLambdaAPI is a service that integrates with AWS Lambda to provide a Breeze API for DynamoDB operations.
///
/// It supports operations such as create, read, update, delete, and list items in a DynamoDB table using a BreezeCodable.
///
/// This Service is designed to work with ServiceLifecycle, allowing it to be run and stopped gracefully.
public actor BreezeLambdaAPI<T: BreezeCodable>: Service {
    
    let logger = Logger(label: "service-group-breeze-lambda-api")
    let timeout: TimeAmount
    private let serviceGroup: ServiceGroup
    private let apiConfig: any APIConfiguring
    
    /// Initializes the BreezeLambdaAPI with the provided API configuration.
    /// - Parameter apiConfig: An object conforming to `APIConfiguring` that provides the necessary configuration for the Breeze API.
    /// - Throws: An error if the configuration is invalid or if the service fails to initialize.
    ///
    /// This initializer sets up the Breeze Lambda API service with the specified configuration, including the DynamoDB service and the operation to be performed.
    ///
    /// - Note:
    ///   - The `apiConfig` parameter must conform to the `APIConfiguring` protocol, which provides the necessary configuration details for the Breeze API.
    ///   - The default implementation uses `BreezeAPIConfiguration`, but you can provide your own implementation if needed.
    public init(apiConfig: APIConfiguring = BreezeAPIConfiguration()) async throws {
        do {
            self.apiConfig = apiConfig
            self.timeout = .seconds(apiConfig.dbTimeout)
            let config = try apiConfig.getConfig()
            let httpConfig = BreezeHTTPClientConfig(
                timeout: .seconds(60),
                logger: logger
            )
            let operation = try apiConfig.operation()
            let dynamoDBService = await BreezeDynamoDBService(
                config: config,
                httpConfig: httpConfig,
                logger: logger
            )
            let breezeLambdaService = BreezeLambdaService<T>(
                dynamoDBService: dynamoDBService,
                operation: operation,
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
    
    /// Runs the BreezeLambdaAPI service.
    /// This method starts the internal ServiceGroup and begins processing requests.
    /// - Throws: An error if the service fails to start or if an issue occurs during execution.
    ///
    /// The internal ServiceGroup will handle the lifecycle of the BreezeLambdaAPI, including starting and stopping the service gracefully.
    public func run() async throws {
        logger.info("Starting BreezeLambdaAPI...")
        try await serviceGroup.run()
        logger.info("BreezeLambdaAPI is stopped successfully")
    }
}
