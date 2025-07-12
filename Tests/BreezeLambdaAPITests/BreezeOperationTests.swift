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

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Testing
@testable import BreezeLambdaAPI

@Suite
struct BreezeOperationTests {
    @Test
    func test_createOperation() {
        #expect(BreezeOperation(handler: "build/Products.create") == BreezeOperation.create)
        #expect(BreezeOperation(handler: "create") == BreezeOperation.create)
    }
    
    @Test
    func test_readOperation() {
        #expect(BreezeOperation(handler: "build/Products.read") == BreezeOperation.read)
        #expect(BreezeOperation(handler: "read") == BreezeOperation.read)
    }
    
    @Test
    func test_updateOperation() {
        #expect(BreezeOperation(handler: "build/Products.update") == BreezeOperation.update)
        #expect(BreezeOperation(handler: "update") == BreezeOperation.update)
    }
    
    @Test
    func test_deleteOperation() {
        #expect(BreezeOperation(handler: "build/Products.delete") == BreezeOperation.delete)
        #expect(BreezeOperation(handler: "delete") == BreezeOperation.delete)
    }
    
    @Test
    func test_listOperation() {
        #expect(BreezeOperation(handler: "build/Products.list") == BreezeOperation.list)
        #expect(BreezeOperation(handler: "list") == BreezeOperation.list)
    }
}
