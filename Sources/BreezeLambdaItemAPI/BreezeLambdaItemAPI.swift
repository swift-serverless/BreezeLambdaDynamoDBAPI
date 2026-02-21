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

import Configuration
import BreezeLambdaAPI
import BreezeDynamoDBService

/// The BreezeLambdaItemAPI is an example of a Breeze Lambda API that interacts with DynamoDB to manage items.
/// Use this example to understand how to create a Breeze Lambda API that can list, create, update, and delete items in a DynamoDB table.

/// The Item struct represents an item in the DynamoDB table.
/// It conforms to Codable for easy encoding and decoding to/from JSON.
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

/// BreezeCodable is a protocol that allows the Item struct to be used with Breeze Lambda API.
extension Item: BreezeCodable { }


@main
struct BreezeLambdaItemAPI {
    static func main() async throws {
#if DEBUG
        do {
            let config = ConfigReader(
                providers: [
                    EnvironmentVariablesProvider(),
                    try await FileProvider<JSONSnapshot>(filePath: "Sources/BreezeLambdaItemAPI/Resources/breeze-item-config.json")
                ]
            )
            let configuration = BreezeAPIConfiguration(reader: config)
            let lambdaAPIService = try await BreezeLambdaAPI<Item>(apiConfig: configuration)
            try await lambdaAPIService.run()
        } catch {
            print(error.localizedDescription)
        }
#else
        // In production, you can run the BreezeLambdaAPI without the API configuration.
        // This will use the default configuration for the BreezeDynamoDBService.
        // Make sure to set the environment variables for the DynamoDB service:
        // DYNAMODB_TABLE_NAME, DYNAMODB_KEY_NAME, and AWS_REGION.
        do {
            try await BreezeLambdaAPI<Item>().run()
        } catch {
            print(error.localizedDescription)
        }
#endif
    }
}
