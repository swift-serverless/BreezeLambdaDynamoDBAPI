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
import SotoDynamoDB
import AsyncHTTPClient

extension Lambda {
    
    static func test<T: BreezeCodable>(
        _ handlerType: BreezeLambdaHandler<T>.Type,
        config: BreezeDynamoDBConfig,
        operation: BreezeOperation,
        response: (any BreezeCodable)?,
        keyedResponse: (any BreezeCodable)?,
        with event: BreezeLambdaHandler.Event) async throws -> BreezeLambdaHandler<T>.Output {
            
        let logger = Logger(label: "evaluateHandler")
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        
        let awsClient = AWSClient()
        let db = SotoDynamoDB.DynamoDB(client: awsClient)
        let dbManager = BreezeDynamoDBManagerMock(db: db, tableName: config.tableName, keyName: config.keyName)
        let sut = handlerType.init(dbManager: dbManager, operation: operation)

        let closureHandler = ClosureHandler { event, context in
            //Inject Mock Response
            await dbManager.setupMockResponse(response: response, keyedResponse: keyedResponse)
            // Execute Handler
            return try await sut.handle(event, context: context)
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
        try await awsClient.shutdown()
        return try decoder.decode(BreezeLambdaHandler<T>.Output.self, from: result)
    }
}
