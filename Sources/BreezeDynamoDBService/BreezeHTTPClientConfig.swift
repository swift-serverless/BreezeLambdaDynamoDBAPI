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

import Logging
import NIOCore

/// Defines the errors that can occur in the Breeze Client Service.
public enum BreezeClientServiceError: Error {
    case invalidHttpClient
}

/// Configuration structure for the Breeze HTTP client.
public struct BreezeHTTPClientConfig: Sendable {
    
    /// Initializes a new instance of BreezeHTTPClientConfig.
    /// - Parameters:
    ///   - timeout: The timeout duration for HTTP requests.
    ///   - logger: The logger to use for logging messages.
    public init(timeout: TimeAmount, logger: Logger) {
        self.timeout = timeout
        self.logger = logger
    }
    
    /// The timeout duration for HTTP requests.
    public let timeout: TimeAmount
    
    /// The logger to use for logging messages.
    public let logger: Logger
}
