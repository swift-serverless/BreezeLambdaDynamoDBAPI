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

@testable import BreezeLambdaAPI
import Logging
import Testing
import ServiceLifecycle
import ServiceLifecycleTestKit
import BreezeDynamoDBService

struct APIConfiguration: APIConfiguring {
    var dbTimeout: Int64 = 30
    
    func operation() throws -> BreezeOperation {
        .list
    }
    func getConfig() throws -> BreezeDynamoDBConfig {
        BreezeDynamoDBConfig(region: .useast1, tableName: "Breeze", keyName: "itemKey", endpoint: "http://127.0.0.1:4566")
    }
}

@Suite(.serialized)
struct BreezeLambdaAPITests {
    
    let logger = Logger(label: "BreezeHTTPClientServiceTests")
    
    @Test
    func test_breezeLambdaAPI_whenValidEnvironment() async throws {
        do {
        try await testGracefulShutdown { gracefulShutdownTestTrigger in
            let (gracefulStream, continuation) = AsyncStream<Void>.makeStream()
            try await withThrowingTaskGroup(of: Void.self) { group in
                let sut = try await BreezeLambdaAPI<Product>(apiConfig: APIConfiguration())
                group.addTask {
                    try await withGracefulShutdownHandler{
                        try await sut.run()
                    } onGracefulShutdown: {
                        logger.info("On Graceful Shutdown")
                        continuation.yield()
                    }
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    gracefulShutdownTestTrigger.triggerGracefulShutdown()
                }
                for await _ in gracefulStream {
                    continuation.finish()
                    logger.info("Graceful shutdown stream received")
                    group.cancelAll()
                }
            }
        }
        } catch {
            logger.error("Error during test: \(error)")
            throw error
        }
    }
    
    @Test
    func test_breezeLambdaAPI_whenInvalidEnvironment() async throws {
        await #expect(throws: BreezeLambdaAPIError.self) {
            let (errorStream, continuation) = AsyncStream<Error>.makeStream()
            try await testGracefulShutdown { gracefulShutdownTestTrigger in
                try await withThrowingTaskGroup(of: Void.self) { group in
                    let sut = try await BreezeLambdaAPI<Product>()
                    group.addTask {
                        try await withGracefulShutdownHandler {
                            do {
                                try await sut.run()
                            } catch {
                                continuation.yield(error)
                                continuation.finish()
                            }
                        } onGracefulShutdown: {
                            logger.info("Performing onGracefulShutdown")
                        }
                    }
                    group.addTask {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        gracefulShutdownTestTrigger.triggerGracefulShutdown()
                    }
                    for await _ in errorStream {
                        logger.info("Error stream received")
                        group.cancelAll()
                    }
                }
            }
        }
    }
}
