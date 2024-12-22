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

import ServiceLifecycle
import AsyncHTTPClient
import NIOCore
import BreezeDynamoDBService
import AWSLambdaRuntime
import AWSLambdaEvents
import Logging

actor BreezeLambdaService<T: BreezeCodable>: Service {
    
    let dynamoDBService: BreezeDynamoDBService
    let logger: Logger
    
    init(dynamoDBService: BreezeDynamoDBService, logger: Logger) {
        self.dynamoDBService = dynamoDBService
        self.logger = logger
    }
    
    var breezeApi: BreezeLambdaAPIHandler<T>?
    
    func handler(event: APIGatewayV2Request, context: LambdaContext) async throws -> APIGatewayV2Response {
        guard let breezeApi else { throw BreezeLambdaAPIError.invalidHandler }
        return try await breezeApi.handle(event, context: context)
    }
    
    func run() async throws {
        do {
            logger.info("Initializing BreezeLambdaAPIHandler...")
            let breezeApi = try await BreezeLambdaAPIHandler<T>(service: dynamoDBService)
            self.breezeApi = breezeApi
            logger.info("Starting BreezeLambdaAPIHandler...")
            let runtime = LambdaRuntime(body: handler)
            try await runtime.run()
            logger.info("BreezeLambdaAPIHandler stopped.")
        } catch {
            logger.error("\(error.localizedDescription)")
            fatalError("\(error.localizedDescription)")
        }
    }
}
