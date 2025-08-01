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

import BreezeDynamoDBService
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct Product: BreezeCodable {
    var key: String
    let name: String
    let description: String
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case key = "sku"
        case name
        case description
        case createdAt
        case updatedAt
    }
}

enum TestError: Error {
    case missingFixture
}
