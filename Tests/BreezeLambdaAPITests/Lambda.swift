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

import AWSLambdaEvents
import AWSLambdaRuntime
import BreezeDynamoDBService
import BreezeHTTPClientService
@testable import BreezeLambdaAPI
@testable import AWSLambdaRuntimeCore
import AWSLambdaTesting
import Logging
import NIO
import ServiceLifecycle
import ServiceLifecycleTestKit
import Foundation
import Logging
import Testing

extension Lambda {
    
    enum TestState {
        case none
        case running
        case result(BreezeLambdaAPIHandler.Output)
    }
    
    static func test<T: BreezeCodable>(
        _ handlerType: BreezeLambdaAPIHandler<T>.Type,
        with event: BreezeLambdaAPIHandler.Event) async throws -> BreezeLambdaAPIHandler<T>.Output {
            
        let logger = Logger(label: "evaluateHandler")
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        
        return try await testGracefulShutdown { gracefulShutdownTestTrigger in
            let httpClientService = BreezeHTTPClientService(timeout: .seconds(1), logger: logger)
            let config = BreezeDynamoDBService.Config(
                httpClientService: httpClientService,
                region: .useast1,
                tableName: "Breeze",
                keyName: "key",
                endpoint: nil,
                logger: logger)
            let dynamoDBService = BreezeDynamoDBService(with: config)
            let sut = try await handlerType.init(service: dynamoDBService)
            
            let serviceGroup = ServiceGroup(
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
                        )
                    ],
                    logger: logger
                )
            )
            
            let testState = try await withThrowingTaskGroup(of: TestState.self) { group in
                group.addTask {
                    try await serviceGroup.run()
                    return TestState.running
                }
                
                group.addTask {
                    defer {
                        gracefulShutdownTestTrigger.triggerGracefulShutdown()
                    }
                    let closureHandler = ClosureHandler { event, context in
                        try await sut.handle(event, context: context)
                    }
                    
                    var handler = LambdaCodableAdapter(
                        encoder: encoder,
                        decoder: decoder,
                        handler: LambdaHandlerAdapter(handler: closureHandler)
                    )
                    let data = try encoder.encode(event)
                    let event = ByteBuffer(data: data)
                    let writer = MockLambdaResponseStreamWriter()
                    let context = LambdaContext.__forTestsOnly(
                        requestID: UUID().uuidString,
                        traceID: UUID().uuidString,
                        invokedFunctionARN: "arn:",
                        timeout: .milliseconds(6000),
                        logger: logger
                    )
                    
                    try await handler.handle(event, responseWriter: writer, context: context)
                    
                    let result = await writer.output ?? ByteBuffer()
                    return TestState.result(try decoder.decode(BreezeLambdaAPIHandler<T>.Output.self, from: result))
                }
                for try await value in group {
                    switch value {
                    case .none, .running:
                        break
                    case .result:
                        return value
                    }
                }
                return TestState.none
            }
            
            switch testState {
            case .none, .running:
                return APIGatewayV2Response(with: "", statusCode: .noContent)
            case .result(let response):
                return response
            }
        }
    }
}
