//
//  TestAPIEndpoint.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/5.
//

import Foundation
import Utilities

@testable import Networking

class TestAppSettings {
    static let shared = TestAppSettings()
    
    enum TestAPIEnvironment: CaseIterable {
        case staging, production
    }
    let currentTestAPIEnvironment: TestAPIEnvironment = .staging
    
    var testAPIDomain: String {
        switch currentTestAPIEnvironment {
        case .staging:
            return "https://staging.example.com"
        case .production:
            return "https://api.example.com"
        }
    }
}

class TestAPIEndpoint: HTTPEndpoint {
    
    init(
        path: String,
        method: HTTPMethod,
        headers: [HTTPHeader],
        parameter: HTTPParameter?
    ) {
        super.init(
            domain: { TestAppSettings.shared.testAPIDomain },
            path: path,
            method: method,
            headers: headers,
            parameter: parameter
        )
    }
    
    static func plain() -> TestAPIEndpoint {
        TestAPIEndpoint(
            path: "/plain",
            method: .get,
            headers: [],
            parameter: nil
        )
    }
    
    static func plainWithHeaderValue(accessToken: String) -> TestAPIEndpoint {
        TestAPIEndpoint(
            path: "/plainWithHeaderValue",
            method: .get,
            headers: [
                HTTPHeader(.authorization, accessToken),
                HTTPHeader("apikey", accessToken)
            ],
            parameter: nil
        )
    }
    
    static func url(queries: [String: String]) -> TestAPIEndpoint {
        TestAPIEndpoint(
            path: "/urlQueries",
            method: .get,
            headers: [],
            parameter: .url(queries: queries)
        )
    }
    
    static func body(data: Data) -> TestAPIEndpoint {
        TestAPIEndpoint(
            path: "/bodyWithData",
            method: .post,
            headers: [],
            parameter: .body(.data(data))
        )
    }
    
    static func body(encodable: Encodable) -> TestAPIEndpoint {
        TestAPIEndpoint(
            path: "/bodyWithEncodable",
            method: .post,
            headers: [],
            parameter: .body(.json(encodable))
        )
    }
    
    static func body(dictionary: [String: AnyEncodable]) -> TestAPIEndpoint {
        TestAPIEndpoint(
            path: "/bodyWithDictionary",
            method: .post,
            headers: [],
            parameter: .dictionary(dictionary)
        )
    }
    
    static func invalidURL() -> TestAPIEndpoint {
        TestAPIEndpoint(
            path: " /invalidURL",
            method: .get,
            headers: [],
            parameter: nil
        )
    }
    
    static func jsonEncodingFailure(encodable: Encodable) -> TestAPIEndpoint {
        TestAPIEndpoint(
            path: "/jsonEncodingFailure",
            method: .post,
            headers: [],
            parameter: .body(.json(encodable))
        )
    }
}
