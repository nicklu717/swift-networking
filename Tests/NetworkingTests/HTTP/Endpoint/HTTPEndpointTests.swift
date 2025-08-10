//
//  HTTPEndpointTests.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/6/22.
//

import Testing
import Foundation

@testable import Networking

@Suite
struct HTTPEndpointTests {
    
    @Suite
    struct MakeRequestTests {
        
        @Test(arguments: MockAPIEnvironment.allCases)
        func success(environment: MockAPIEnvironment) throws {
            try success(endpoint: .plain, environment: environment)
        }
        
        @Test
        func success() throws {
            let array: [MockAPIEndpoint] = [
                .plain,
                .plainWithHeaderValue(accessToken: "mock_access_token"),
                .url(queries: ["product_id": "12345"]),
                .body(data: "mock_data".data(using: .utf8)!),
                .body(encodable: ["product_id": "12345"])
            ]
            try array.forEach {
                try success(endpoint: $0, environment: .production)
            }
        }
        
        private func success(endpoint: MockAPIEndpoint, environment: MockAPIEnvironment) throws {
            var successRequest: URLRequest?
            var failureError: MockAPIEndpoint.MakeRequestError?
            
            switch endpoint.makeRequest(for: environment) {
            case .success(let request):
                successRequest = request
            case .failure(let error):
                failureError = error
            }
            
            let request = try #require(successRequest)
            
            var queryString = ""
            if case .url(let queries) = endpoint.parameter {
                guard !queries.isEmpty else { return }
                queryString = "?\(queries.map { "\($0)=\($1)" }.joined(separator: "&"))"
            }
            #expect(request.url?.absoluteString == endpoint.domain(environment) + endpoint.path + queryString)
            #expect(request.httpMethod == endpoint.method.rawValue)
            #expect(request.allHTTPHeaderFields?.count == endpoint.headers.count)
            endpoint.headers.map(\.entry).forEach {
                #expect(request.value(forHTTPHeaderField: $0.field.rawName) == $0.value)
            }
            if let parameter = endpoint.parameter {
                switch parameter {
                case .url(let queries):
                    guard !queries.isEmpty else { break }
                    queryString = "?\(queries.map { "\($0)=\($1)" }.joined(separator: "&"))"
                case .body(let bodyType):
                    switch bodyType {
                    case .data(let data):
                        #expect(request.httpBody == data)
                    case .json(let encodable):
                        let data = try #require(try JSONEncoder().encode(encodable))
                        #expect(request.httpBody == data)
                    }
                }
            }
            #expect(failureError == nil)
        }
        
        @Test(arguments: MockAPIEnvironment.allCases)
        func invalidURL(environment: MockAPIEnvironment) {
            let endpoint: MockAPIEndpoint = .invalidURL
            var successRequest: URLRequest?
            var invalidURLError: MockAPIEndpoint.MakeRequestError?
            var otherFailureError: MockAPIEndpoint.MakeRequestError?
            
            switch endpoint.makeRequest(for: environment) {
            case .success(let request):
                successRequest = request
            case .failure(let error):
                switch error {
                case .invalidURL:
                    invalidURLError = error
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successRequest == nil)
            #expect(invalidURLError != nil)
            #expect(otherFailureError == nil)
        }
        
        @Test(arguments: MockAPIEnvironment.allCases)
        func jsonEncodingFailure(environment: MockAPIEnvironment) {
            let endpoint: MockAPIEndpoint = .jsonEncodingFailure(encodable: InvalidEncodable())
            var successRequest: URLRequest?
            var jsonEncodingFailureError: MockAPIEndpoint.MakeRequestError?
            var otherFailureError: MockAPIEndpoint.MakeRequestError?
            
            switch endpoint.makeRequest(for: environment) {
            case .success(let request):
                successRequest = request
            case .failure(let error):
                switch error {
                case .jsonEncodingFailure:
                    jsonEncodingFailureError = error
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successRequest == nil)
            #expect(jsonEncodingFailureError != nil)
            #expect(otherFailureError == nil)
        }
    }
}

// MARK: - Mock Encodables
extension HTTPEndpointTests {
    
    struct InvalidEncodable: Encodable {
        let float: Float = .infinity
    }
}
