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

import BreezeHTTPClientService
import Logging
import Testing
import ServiceLifecycle
import ServiceLifecycleTestKit

@Suite
struct BreezeHTTPClientServiceTests {
    
    let logger = Logger(label: "BreezeHTTPClientServiceTests")
    
    @Test
    func test_breezeHTTPClientServiceGracefulShutdown() async throws {
        try await testGracefulShutdown { gracefulShutdownTestTrigger in
            try await withThrowingTaskGroup(of: Void.self) { group in
                let sut = BreezeHTTPClientService(timeout: .seconds(1), logger: logger)
                group.addTask {
                    try await withGracefulShutdownHandler {
                        try await sut.run()
                        let httpClient = await sut.httpClient
                        #expect(httpClient != nil)
                    } onGracefulShutdown: {
                        logger.info("Performing onGracefulShutdown")
                    }
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 10_000_000)
                    gracefulShutdownTestTrigger.triggerGracefulShutdown()
                }
                try await group.waitForAll()
            }
        }
    }
}
