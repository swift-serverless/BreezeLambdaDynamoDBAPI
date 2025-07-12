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

/// BreezeOperation is an enumeration that defines the operations supported by Breeze Lambda API.
///  It includes operations such as create, read, update, delete, and list.
public enum BreezeOperation: String, Sendable {
    case create
    case read
    case update
    case delete
    case list

    /// Initializes a BreezeOperation from a handler string.
    ///
    /// - Parameter handler: A string representing the handler, typically in the format "module.operation".
    /// - Returns: An optional BreezeOperation if the handler string can be parsed successfully.
    /// - Note: This initializer extracts the operation from the handler string by splitting it at the last dot (.) and matching it to a BreezeOperation case.
    init?(handler: String) {
        guard let value = handler.split(separator: ".").last,
              let operation = BreezeOperation(rawValue: String(value))
        else {
            return nil
        }
        self = operation
    }
}
