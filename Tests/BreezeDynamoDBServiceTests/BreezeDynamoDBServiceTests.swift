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
import AsyncHTTPClient
import Logging
import Testing
@testable import BreezeDynamoDBService

@Suite
struct BreezeDynamoDBServiceTests {
    @Test
    func testInitPrepareBreezeDynamoDBManager() async throws {
        let sut = await makeBreezeDynamoDBConfig()
        let manager =
sut.dbManager
        #expect(manager is BreezeDynamoDBManager, "Expected BreezeDynamoDBManager instance")
        try await sut.onGracefulShutdown()
    }
    
    @Test
    func testGracefulShutdownCanBeCalledMultipleTimes() async throws {
        let sut = await makeBreezeDynamoDBConfig()
        try await sut.onGracefulShutdown()
        await #expect(throws: Error.self) {
            try await sut.onGracefulShutdown()
        }
    }
    
    @Test
    func testMockInjection() async throws {
        let config = BreezeDynamoDBConfig(
            region: .useast1,
            tableName: "TestTable",
            keyName: "TestKey",
        )
        let logger = Logger(label: "BreezeDynamoDBServiceTests")
        let httpConfig = BreezeHTTPClientConfig(timeout: .seconds(10), logger: logger)
        let sut = BreezeDynamoDBService(
            config: config,
            httpConfig: httpConfig,
            logger: logger,
            DBManagingType: BreezeDynamoDBManagerMock.self
        )
        let manager = sut.dbManager
        #expect(manager is BreezeDynamoDBManagerMock, "Expected BreezeDynamoDBManager instance")
        try await sut.onGracefulShutdown()
    }
    
    private func makeBreezeDynamoDBConfig() async -> BreezeDynamoDBService {
        let config = BreezeDynamoDBConfig(
            region: .useast1,
            tableName: "TestTable",
            keyName: "TestKey",
        )
        let logger = Logger(label: "BreezeDynamoDBServiceTests")
        let httpConfig = BreezeHTTPClientConfig(timeout: .seconds(10), logger: logger)
        return BreezeDynamoDBService(
            config: config,
            httpConfig: httpConfig,
            logger: logger,
        )
    }
}
