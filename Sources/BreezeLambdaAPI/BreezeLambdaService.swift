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

/// Service for processing AWS API Gateway events with BreezeCodable models.
///
/// `BreezeLambdaService<T>` is a key component in the serverless architecture that:
/// - Acts as a bridge between AWS Lambda runtime and DynamoDB operations
/// - Processes incoming API Gateway events through a type-safe interface
/// - Manages the lifecycle of AWS Lambda handlers for BreezeCodable models
/// - Coordinates graceful shutdown procedures to ensure clean resource release
///
/// The service leverages Swift concurrency features through the actor model to ensure
/// thread-safe access to shared resources while processing multiple Lambda invocations.
/// It delegates the actual processing of events to a specialized `BreezeLambdaHandler`
/// which performs the database operations via the injected `BreezeDynamoDBService`.
///
/// This service is designed to be initialized and run as part of a `ServiceGroup`
/// within the AWS Lambda execution environment.
actor BreezeLambdaService<T: BreezeCodable>: Service {
    
    /// Database service that provides access to the underlying DynamoDB operations.
    ///
    /// This service is responsible for all database interactions and connection management.
    let dynamoDBService: BreezeDynamoDBServing
    
    /// Operation type that determines the behavior of this service instance.
    ///
    /// Defines whether this Lambda will perform create, read, update, delete, or list operation
    let operation: BreezeOperation
    
    /// Logger instance for tracking service lifecycle events and errors.
    ///
    /// Used throughout the service to provide consistent logging patterns.
    let logger: Logger
    
    /// Initializes a new instance of `BreezeLambdaService`.
    /// - Parameters:
    ///   - dynamoDBService: Service providing DynamoDB operations and connection management
    ///   - operation: The specific CRUD operation this Lambda instance will perform
    ///   - logger: Logger instance for service monitoring and debugging
    init(dynamoDBService: BreezeDynamoDBServing, operation: BreezeOperation, logger: Logger) {
        self.dynamoDBService = dynamoDBService
        self.operation = operation
        self.logger = logger
    }
    
    /// Handler instance that processes business logic for the configured operation.
    ///
    /// Lazily initialized during the `run()` method to ensure proper service startup sequence.
    var breezeApi: BreezeLambdaHandler<T>?
    
    /// Handler method that processes incoming AWS Lambda events.
    func handler(event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        guard let breezeApi else { throw BreezeLambdaAPIError.invalidHandler }
        return try await breezeApi.handle(event, context: context)
    }
    
    /// Runs the service allowing graceful shutdown.
    ///
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
    ///
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
