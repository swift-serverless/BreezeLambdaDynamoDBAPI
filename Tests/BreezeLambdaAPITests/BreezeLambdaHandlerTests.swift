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

import AWSLambdaEvents
import AWSLambdaRuntime
import ServiceLifecycle
import ServiceLifecycleTestKit
import BreezeDynamoDBService
import BreezeHTTPClientService
@testable import BreezeLambdaAPI
@testable import AWSLambdaRuntimeCore
import Testing
import Logging
import AsyncHTTPClient
import NIOCore
import Foundation


@Suite
struct BreezeLambdaHandlerTests {
    
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    let logger = Logger(label: "BreezeLambdaAPITests")
    let config = BreezeDynamoDBConfig(region: .useast1, tableName: "Breeze", keyName: "sku")
    
    @Test
    func test_create() async throws {
        let response = Fixtures.product2023
        let createRequest = try Fixtures.fixture(name: Fixtures.postProductsRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .create,
            response: response,
            keyedResponse: nil,
            with: request
        )
        let product: Product = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .created)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(product.key == "2023")
        #expect(product.name == "Swift Serverless API with async/await! 🚀🥳")
        #expect(product.description == "BreezeLambaAPI is magic 🪄!")
    }

    @Test
    func test_create_whenInvalidItem_thenError() async throws {
        let createRequest = try Fixtures.fixture(name: Fixtures.postInvalidRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .create,
            response: nil,
            keyedResponse: nil,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .forbidden)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }
    
    @Test
    func test_create_whenMissingItem_thenError() async throws {
        let createRequest = try Fixtures.fixture(name: Fixtures.postProductsRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: createRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .create,
            response: nil,
            keyedResponse: nil,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .forbidden)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }

    @Test
    func test_read() async throws {
        let keyedResponse = Fixtures.product2023
        let readRequest = try Fixtures.fixture(name: Fixtures.getProductsSkuRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: readRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .read,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: Product = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .ok)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.key == "2023")
        #expect(response.name == "Swift Serverless API with async/await! 🚀🥳")
        #expect(response.description == "BreezeLambaAPI is magic 🪄!")
    }

    @Test
    func test_read_whenInvalidRequest_thenError() async throws {
        let keyedResponse = Fixtures.product2023
        let readRequest = try Fixtures.fixture(name: Fixtures.getInvalidRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: readRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .read,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .forbidden)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }

    @Test
    func test_read_whenMissingItem_thenError() async throws {
        let keyedResponse = Fixtures.product2022
        let readRequest = try Fixtures.fixture(name: Fixtures.getProductsSkuRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: readRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .read,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .notFound)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }

    @Test
    func test_update() async throws {
        let keyedResponse = Fixtures.product2023
        let updateRequest = try Fixtures.fixture(name: Fixtures.putProductsRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: updateRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .update,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: Product = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .ok)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.key == "2023")
        #expect(response.name == "Swift Serverless API with async/await! 🚀🥳")
        #expect(response.description == "BreezeLambaAPI is magic 🪄!")
    }
    
    @Test
    func test_update_whenInvalidRequest_thenError() async throws {
        let keyedResponse = Fixtures.product2023
        let updateRequest = try Fixtures.fixture(name: Fixtures.getInvalidRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: updateRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .update,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .forbidden)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }

    @Test
    func test_update_whenMissingItem_thenError() async throws {
        let keyedResponse = Fixtures.product2022
        let updateRequest = try Fixtures.fixture(name: Fixtures.putProductsRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: updateRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .update,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .notFound)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }

    @Test
    func test_delete() async throws {
        let keyedResponse = Fixtures.product2023
        let deleteProductsSku = try Fixtures.fixture(name: Fixtures.deleteProductsSkuRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: deleteProductsSku)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .delete,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: BreezeEmptyResponse = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .ok)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response != nil)
    }
    
    @Test
    func test_delete_whenRequestIsOutaded() async throws {
        let keyedResponse = Fixtures.productUdated2023
        let deleteProductsSku = try Fixtures.fixture(name: Fixtures.deleteProductsSkuRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: deleteProductsSku)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .delete,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: BreezeEmptyResponse = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .notFound)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response != nil)
    }
    
    @Test
    func test_delete_whenInvalidRequest_thenError() async throws {
        let keyedResponse = Fixtures.product2023
        let deleteProductsSku = try Fixtures.fixture(name: Fixtures.getInvalidRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: deleteProductsSku)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .delete,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .forbidden)
        #expect(response.error == "invalidRequest")
    }

    @Test
    func test_delete_whenMissingItem_thenError() async throws {
        let keyedResponse = Fixtures.product2022
        let deleteProductsSku = try Fixtures.fixture(name: Fixtures.deleteProductsSkuRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: deleteProductsSku)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .delete,
            response: nil,
            keyedResponse: keyedResponse,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .notFound)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidRequest")
    }

    @Test
    func test_list() async throws {
        let response = Fixtures.product2023
        let listRequest = try Fixtures.fixture(name: Fixtures.getProductsRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: listRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .list,
            response: response,
            keyedResponse: nil,
            with: request
        )
        let product: ListResponse<Product> = try apiResponse.decodeBody()
        let item = try #require(product.items.first)
//        #expect(BreezeDynamoDBServiceMock.limit == 1)
//        #expect(BreezeDynamoDBServiceMock.exclusiveKey == "2023")
        #expect(apiResponse.statusCode == .ok)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(item.key == "2023")
        #expect(item.name == "Swift Serverless API with async/await! 🚀🥳")
        #expect(item.description == "BreezeLambaAPI is magic 🪄!")
    }

    @Test
    func test_list_whenError() async throws {
        let listRequest = try Fixtures.fixture(name: Fixtures.getProductsRequest, type: "json")
        let request = try decoder.decode(APIGatewayV2Request.self, from: listRequest)
        let apiResponse: APIGatewayV2Response = try await Lambda.test(
            BreezeLambdaHandler<Product>.self,
            config: config,
            operation: .list,
            response: nil,
            keyedResponse: nil,
            with: request
        )
        let response: APIGatewayV2Response.BodyError = try apiResponse.decodeBody()
        #expect(apiResponse.statusCode == .forbidden)
        #expect(apiResponse.headers == [ "Content-Type": "application/json" ])
        #expect(response.error == "invalidItem")
    }
}

final actor MockLambdaResponseStreamWriter: LambdaResponseStreamWriter {
    private var buffer: ByteBuffer?

    var output: ByteBuffer? {
        self.buffer
    }

    func writeAndFinish(_ buffer: ByteBuffer) async throws {
        self.buffer = buffer
    }

    func write(_ buffer: ByteBuffer) async throws {
        fatalError("Unexpected call")
    }

    func finish() async throws {
        fatalError("Unexpected call")
    }
}
