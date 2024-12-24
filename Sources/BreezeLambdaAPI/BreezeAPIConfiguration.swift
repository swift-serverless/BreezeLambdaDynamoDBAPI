//
//  BreezeAPIConfiguration.swift
//  BreezeLambdaDynamoDBAPI
//
//  Created by Andrea Scuderi on 24/12/2024.
//

import SotoDynamoDB
import BreezeDynamoDBService
import AWSLambdaRuntime

public protocol APIConfiguring {
    var dbTimeout: Int64 { get }
    func operation() throws -> BreezeOperation
    func getConfig() throws -> BreezeDynamoDBConfig
}

public struct BreezeAPIConfiguration: APIConfiguring {
    
    public init() {}
    
    public let dbTimeout: Int64 = 30
    
    public func operation() throws -> BreezeOperation {
        guard let handler = Lambda.env("_HANDLER"),
              let operation = BreezeOperation(handler: handler)
        else {
            throw BreezeLambdaAPIError.invalidHandler
        }
        return operation
    }
    
    public func getConfig() throws -> BreezeDynamoDBConfig {
        BreezeDynamoDBConfig(
            region: currentRegion(),
            tableName: try tableName(),
            keyName: try keyName(),
            endpoint: endpoint()
        )
    }
    
    func currentRegion() -> Region {
        if let awsRegion = Lambda.env("AWS_REGION") {
            let value = Region(rawValue: awsRegion)
            return value
        } else {
            return .useast1
        }
    }
    
    func tableName() throws -> String {
        guard let tableName = Lambda.env("DYNAMO_DB_TABLE_NAME") else {
            throw BreezeLambdaAPIError.tableNameNotFound
        }
        return tableName
    }
    
    func keyName() throws -> String {
        guard let tableName = Lambda.env("DYNAMO_DB_KEY") else {
            throw BreezeLambdaAPIError.keyNameNotFound
        }
        return tableName
    }
    
    func endpoint() -> String? {
        if let localstack = Lambda.env("LOCALSTACK_ENDPOINT"),
           !localstack.isEmpty {
            return localstack
        }
        return nil
    }
}
