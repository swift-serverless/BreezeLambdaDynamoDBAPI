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

actor BreezeLambdaService<T: BreezeCodable>: Service {
    
    let dynamoDBService: BreezeDynamoDBService
    
    init(dynamoDBService: BreezeDynamoDBService) {
        self.dynamoDBService = dynamoDBService
    }

    func run() async throws {
        let breezeApi = try await BreezeLambdaAPIHandler<T>(service: dynamoDBService)
        let runtime = LambdaRuntime { event, context in
            try await breezeApi.handle(event, context: context)
        }
        try await runtime.run()
    }
}
