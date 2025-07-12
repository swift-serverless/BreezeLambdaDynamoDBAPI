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

import class Foundation.DateFormatter
import struct Foundation.Date
import struct Foundation.TimeZone

/// This file contains extensions for DateFormatter, Date, and String to handle ISO 8601 date formatting and parsing.
/// These extensions provide a convenient way to convert between `Date` objects and their ISO 8601 string representations.
extension DateFormatter {
    static var iso8061: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}

extension Date {
    /// Returns a string representation of the date in ISO 8601 format.
    var iso8601: String {
        let formatter = DateFormatter.iso8061
        return formatter.string(from: self)
    }
}

extension String {
    /// Attempts to parse the string as an ISO 8601 date.
    var iso8601: Date? {
        let formatter = DateFormatter.iso8061
        return formatter.date(from: self)
    }
}
