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

import BreezeLambdaAPI
import BreezeDynamoDBService

struct Item: Codable {
    public var key: String
    public let name: String
    public let description: String
    public var createdAt: String?
    public var updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case key = "itemKey"
        case name
        case description
        case createdAt
        case updatedAt
    }
}

extension Item: BreezeCodable { }

struct APIConfiguration: APIConfiguring {
    let dbTimeout: Int64 = 30
    func operation() throws -> BreezeOperation {
        .list
    }
    
    func getConfig() throws -> BreezeDynamoDBConfig {
        BreezeDynamoDBConfig(region: .useast1, tableName: "Breeze", keyName: "itemKey", endpoint: "http://127.0.0.1:4566")
    }
}

@main
struct BreezeDemoApplication {
    static func main() async throws {
        do {
            let lambdaAPIService = try BreezeLambdaAPI<Item>(apiConfig: APIConfiguration())
            try await lambdaAPIService.run()
        } catch {
            print(error.localizedDescription)
        }
    }
}
