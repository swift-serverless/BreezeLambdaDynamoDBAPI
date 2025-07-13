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

import ServiceLifecycle
import AsyncHTTPClient
import NIOCore
import BreezeDynamoDBService
import AWSLambdaRuntime
import AWSLambdaEvents
import Logging
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// BreezeLambdaService is an actor that provides a service for handling AWS Lambda events using BreezeCodable models.
///
/// It conforms to the `Service` protocol and implements the `handler` method to process incoming events.
///
/// It manages the lifecycle of a BreezeLambdaHandler, which is responsible for handling the actual business logic.
///
/// It also provides a method to run the service and handle graceful shutdowns.
///
/// It operates on a BreezeCodable model type `T` that conforms to the BreezeCodable protocol.
actor BreezeLambdaService<T: BreezeCodable>: Service {
    
    /// DynamoDBService is an instance of BreezeDynamoDBServing that provides access to the DynamoDB database manager.
    let dynamoDBService: BreezeDynamoDBServing
    /// Operation is an instance of BreezeOperation that defines the operation to be performed by the BreezeLambdaHandler.
    let operation: BreezeOperation
    /// Logger is an instance of Logger for logging messages during the service's operation.
    let logger: Logger
    
    /// Initializes a new instance of `BreezeLambdaService`.
    /// - Parameters:
    ///   - dynamoDBService: An instance of `BreezeDynamoDBServing` that provides access to the DynamoDB database manager.
    ///   - operation: The `BreezeOperation` that defines the operation to be performed by the BreezeLambdaHandler.
    ///   - logger: A `Logger` instance for logging messages during the service's operation.
    init(dynamoDBService: BreezeDynamoDBServing, operation: BreezeOperation, logger: Logger) {
        self.dynamoDBService = dynamoDBService
        self.operation = operation
        self.logger = logger
    }
    
    /// BreezeLambdaHandler is an optional instance of BreezeLambdaHandler that will handle the actual business logic.
    var breezeApi: BreezeLambdaHandler<T>?
    
    /// Handler method that processes incoming AWS Lambda events.
    func handler(event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        guard let breezeApi else { throw BreezeLambdaAPIError.invalidHandler }
        return try await breezeApi.handle(event, context: context)
    }
    
    /// Runs the BreezeLambdaService, initializing the BreezeLambdaHandler and starting the Lambda runtime.
    /// - Throws: An error if the service fails to initialize or run.
    func run() async throws {
        let dbManager = await dynamoDBService.dbManager()
        let breezeApi = BreezeLambdaHandler<T>(dbManager: dbManager, operation: self.operation)
        self.breezeApi = breezeApi
        logger.info("Starting BreezeLambdaService...")
        let runtime = LambdaRuntime(body: handler)
        try await runTaskWithCancellationOnGracefulShutdown {
            do {
                try await runtime.run()
            } catch {
                self.logger.error("\(error.localizedDescription)")
                throw error
            }
        } onGracefulShutdown: {
            self.logger.info("Gracefully stoping BreezeLambdaService ...")
            try await self.dynamoDBService.gracefulShutdown()
            self.logger.info("BreezeLambdaService is stopped.")
        }
    }
    
    /// Runs a task with cancellation on graceful shutdown.
    /// - Note: It's required to allow a full process shutdown without leaving tasks hanging.
    private func runTaskWithCancellationOnGracefulShutdown(
        operation: @escaping @Sendable () async throws -> Void,
        onGracefulShutdown: () async throws -> Void
    ) async throws {
        let (cancelOrGracefulShutdown, cancelOrGracefulShutdownContinuation) = AsyncStream<Void>.makeStream()
        let task = Task {
            try await withTaskCancellationOrGracefulShutdownHandler {
                try await operation()
            } onCancelOrGracefulShutdown: {
                cancelOrGracefulShutdownContinuation.yield()
                cancelOrGracefulShutdownContinuation.finish()
            }
        }
        for await _ in cancelOrGracefulShutdown {
            try await onGracefulShutdown()
            task.cancel()
        }
    }
}
