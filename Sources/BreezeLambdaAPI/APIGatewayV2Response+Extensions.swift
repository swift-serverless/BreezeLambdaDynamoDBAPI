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

import struct AWSLambdaEvents.APIGatewayV2Response
import HTTPTypes
import class Foundation.JSONEncoder

extension APIGatewayV2Response {
    private static let encoder = JSONEncoder()
    
    /// Override the headers in APIGatewayV2Response
    static let defaultHeaders = [ "Content-Type": "application/json" ]

    /// A  model representing the body of an error response
    struct BodyError: Codable {
        let error: String
    }
    
    /// Initializer for APIGatewayV2Response with a BodyError
    /// - Parameters:
    ///   - error: Error
    ///   - statusCode: HTTP Status Code
    init(with error: Error, statusCode: HTTPResponse.Status) {
        let bodyError = BodyError(error: String(describing: error))
        self.init(with: bodyError, statusCode: statusCode)
    }
    
    /// Initializer for APIGatewayV2Response with an Encodable object
    /// - Parameters:
    ///   - object: Encodable Object
    ///   - statusCode: HTTP Status Code
    init<Output: Encodable>(with object: Output, statusCode: HTTPResponse.Status) {
        var body = "{}"
        if let data = try? Self.encoder.encode(object) {
            body = String(data: data, encoding: .utf8) ?? body
        }
        self.init(
            statusCode: statusCode,
            headers: APIGatewayV2Response.defaultHeaders,
            body: body,
            isBase64Encoded: false
        )
    }
}
