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

import struct AWSLambdaEvents.APIGatewayV2Request
import class Foundation.JSONDecoder

extension APIGatewayV2Request {
    /// Attempt to convert the query string parameter to an Integer value.
    /// - Parameter key: The `key` of the query string parameter.
    /// - Returns: Query string Int value for parameter param if exists
    public func queryStringParameterToInt(_ key: String) -> Int? {
        guard let value = queryStringParameters?[key] else {
            return nil
        }
        return Int(value)
    }
}

extension APIGatewayV2Request {
    private static let decoder = JSONDecoder()
    
    /// Decodes the body of APIGatewayV2Request
    /// - Returns: Codable Object
    public func bodyObject<T: Codable>() throws -> T {
        guard let body = self.body,
              let dataBody = body.data(using: .utf8)
        else {
            throw BreezeLambdaAPIError.invalidRequest
        }
        return try Self.decoder.decode(T.self, from: dataBody)
    }
}
