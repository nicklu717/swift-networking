//
//  MockAPIEndpoint.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/5.
//

import Foundation

@testable import Networking

class MockAppSettings {
    static let shared = MockAppSettings()
    
    enum MockAPIEnvironment: CaseIterable {
        case staging, production
        
        var mockAPIDomain: String {
            switch self {
            case .staging:
                return "https://staging.example.com"
            case .production:
                return "https://api.example.com"
            }
        }
    }
    let currentMockAPIEnvironment: MockAPIEnvironment = .staging
}

class MockAPIEndpoint: HTTPEndpoint {
    
    init(
        path: String,
        method: HTTPMethod,
        headers: [HTTPHeader],
        parameter: HTTPParameter?
    ) {
        super.init(
            domain: { MockAppSettings.shared.currentMockAPIEnvironment.mockAPIDomain },
            path: path,
            method: method,
            headers: headers,
            parameter: parameter
        )
    }
    
    static func plain() -> MockAPIEndpoint {
        MockAPIEndpoint(
            path: "/plain",
            method: .get,
            headers: [],
            parameter: nil
        )
    }
    
    static func plainWithHeaderValue(accessToken: String) -> MockAPIEndpoint {
        MockAPIEndpoint(
            path: "/plainWithHeaderValue",
            method: .get,
            headers: [
                .authorization(.bearer(token: accessToken)),
            ],
            parameter: nil
        )
    }
    
    static func url(queries: [String: String]) -> MockAPIEndpoint {
        MockAPIEndpoint(
            path: "/urlQueries",
            method: .get,
            headers: [],
            parameter: .url(queries: queries)
        )
    }
    
    static func body(data: Data) -> MockAPIEndpoint {
        MockAPIEndpoint(
            path: "/bodyWithData",
            method: .post,
            headers: [
                .contentType(.json)
            ],
            parameter: .body(.data(data))
        )
    }
    
    static func body(encodable: Encodable) -> MockAPIEndpoint {
        MockAPIEndpoint(
            path: "/bodyWithEncodable",
            method: .post,
            headers: [
                .contentType(.json)
            ],
            parameter: .body(.json(encodable))
        )
    }
    
    static func invalidURL() -> MockAPIEndpoint {
        MockAPIEndpoint(
            path: " /invalidURL",
            method: .get,
            headers: [],
            parameter: nil
        )
    }
    
    static func jsonEncodingFailure(encodable: Encodable) -> MockAPIEndpoint {
        MockAPIEndpoint(
            path: "/jsonEncodingFailure",
            method: .post,
            headers: [],
            parameter: .body(.json(encodable))
        )
    }
}
