//
//  BreezeDemoApplication.swift
//  BreezeLambdaDynamoDBAPI
//
//  Created by Andrea Scuderi on 21/12/2024.
//

import BreezeLambdaAPI
import BreezeDynamoDBService

struct Message: BreezeCodable {
    var key: String
    let message: String
    var createdAt: String?
    var updatedAt: String?
}

@main
struct BreezeDemoApplication {
    static func main() async throws {
        let lambdaAPIService = try BreezeLambdaAPIService<Message>(dbTimeout: 30)
        try await lambdaAPIService.run()
    }
}
