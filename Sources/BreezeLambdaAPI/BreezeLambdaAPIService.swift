//    Copyright 2023 (c) Andrea Scuderi - https://github.com/swift-serverless
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

import SotoDynamoDB
import ServiceLifecycle
import BreezeDynamoDBService
import BreezeHTTPClientService
import AWSLambdaRuntime

public actor BreezeLambdaAPIService<T: BreezeCodable>: Service {
    
    let logger = Logger(label: "service-group")
    let timeout: TimeAmount
    let httpClientService: BreezeHTTPClientService
    let dynamoDBService: BreezeDynamoDBService
    let breezeLambdaService: BreezeLambdaService<T>
    private let serviceGroup: ServiceGroup
    
    static func currentRegion() -> Region {
        if let awsRegion = Lambda.env("AWS_REGION") {
            let value = Region(rawValue: awsRegion)
            return value
        } else {
            return .useast1
        }
    }
    
    static func tableName() throws -> String {
        guard let tableName = Lambda.env("DYNAMO_DB_TABLE_NAME") else {
            throw BreezeLambdaAPIError.tableNameNotFound
        }
        return tableName
    }
    
    static func keyName() throws -> String {
        guard let tableName = Lambda.env("DYNAMO_DB_KEY") else {
            throw BreezeLambdaAPIError.keyNameNotFound
        }
        return tableName
    }
    
    public init(dbTimeout: Int64 = 30) throws {
        self.timeout = .seconds(dbTimeout)
        self.httpClientService = BreezeHTTPClientService(
            timeout: timeout,
            logger: logger
        )
        let config = BreezeDynamoDBService.Config(
            httpClientService: httpClientService,
            region: Self.currentRegion(),
            tableName: try Self.tableName(),
            keyName: try Self.keyName(),
            logger: logger
        )
        self.dynamoDBService = BreezeDynamoDBService(with: config)
        self.breezeLambdaService = BreezeLambdaService<T>(dynamoDBService: dynamoDBService)

        self.serviceGroup = ServiceGroup(
            configuration: .init(
                services: [
                    .init(
                        service: httpClientService,
                        successTerminationBehavior: .ignore,
                        failureTerminationBehavior: .gracefullyShutdownGroup
                    ),
                    .init(
                        service: dynamoDBService,
                        successTerminationBehavior: .gracefullyShutdownGroup,
                        failureTerminationBehavior: .gracefullyShutdownGroup
                    ),
                    .init(
                        service: breezeLambdaService,
                        successTerminationBehavior: .gracefullyShutdownGroup,
                        failureTerminationBehavior: .gracefullyShutdownGroup
                    )
                ],
                logger: logger
            )
        )
    }
    
    public func run() async throws {
        try await serviceGroup.run()
    }
}
