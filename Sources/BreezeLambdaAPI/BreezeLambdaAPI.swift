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

/// Actor implementing a service which transforms API Gateway events containing BreezeCodable items into DynamoDB operations.
///
/// `BreezeLambdaAPI<T>` acts as a bridge between AWS API Gateway and DynamoDB, handling the conversion
/// of incoming requests to the appropriate database operations. The generic parameter `T` represents
/// the data model type that conforms to `BreezeCodable`, ensuring type-safe operations.
///
/// It supports standard CRUD operations:
/// - Create: Insert new items into the DynamoDB table
/// - Read: Retrieve items by their identifier
/// - Update: Modify existing items in the table
/// - Delete: Remove items from the table
/// - List: Query and retrieve multiple items matching specific criteria
///
/// This service leverages the `ServiceLifecycle` package to manage its lifecycle, providing
/// graceful shutdown mechanism. It internally manages a `ServiceGroup` containing
/// a `BreezeLambdaService` and a `BreezeDynamoDBService`, which handle the actual processing
/// of requests and database operations.
///
/// The service is designed to be efficient and scalable for AWS Lambda environments, with configurable
/// timeout settings and comprehensive logging for monitoring and debugging.
public actor BreezeLambdaAPI<T: BreezeCodable>: Service {
    
    let logger = Logger(label: "service-group-breeze-lambda-api")
    private let serviceGroup: ServiceGroup
    private let apiConfig: any APIConfiguring
    private let dynamoDBService: BreezeDynamoDBService
    
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
            let config = try apiConfig.getConfig()
            let httpConfig = BreezeHTTPClientConfig(
                timeout: .seconds(apiConfig.dbTimeout),
                logger: logger
            )
            let operation = try apiConfig.operation()
            self.dynamoDBService = BreezeDynamoDBService(
                config: config,
                httpConfig: httpConfig,
                logger: logger
            )
            let dbManager = dynamoDBService.dbManager
            let breezeApi = BreezeLambdaHandler<T>(dbManager: dbManager, operation: operation)
            let runtime = LambdaRuntime(body: breezeApi.handle)
            self.serviceGroup = ServiceGroup(
                services: [runtime, dynamoDBService],
                gracefulShutdownSignals: [.sigint],
                cancellationSignals: [.sigterm],
                logger: logger
            )
        } catch {
            logger.error("\(error.localizedDescription)")
            throw error
        }
    }
    
    /// Starts the internal ServiceGroup and begins processing requests.
    /// - Throws: An error if the service fails to start or if an issue occurs during execution.
    ///
    /// The internal ServiceGroup will handle the lifecycle of the BreezeLambdaAPI, including starting and stopping the service gracefully.
    public func run() async throws {
        try await serviceGroup.run()
        logger.info("BreezeLambdaAPI is stopped successfully")
    }
}
