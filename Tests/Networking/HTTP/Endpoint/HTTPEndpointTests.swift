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
        
        @Test
        func success() throws {
            let endpoints: [MockAPIEndpoint] = [
                .plain(),
                .plainWithHeaderValue(accessToken: "mock_access_token"),
                .url(queries: ["product_id": "12345"]),
                .body(data: "mock_data".data(using: .utf8)!),
                .body(encodable: ["product_id": "12345"])
            ]
            try endpoints.forEach { endpoint in
                var successRequest: URLRequest?
                var failureError: MockAPIEndpoint.MakeRequestError?
                
                switch endpoint.makeRequest() {
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
                #expect(request.url?.absoluteString == endpoint.domain() + endpoint.path + queryString)
                #expect(request.httpMethod == endpoint.method.rawValue)
                #expect(request.allHTTPHeaderFields?.count == endpoint.headers.count)
                endpoint.headers.forEach {
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
        }
        
        @Test
        func invalidURL() {
            let endpoint: MockAPIEndpoint = .invalidURL()
            var successRequest: URLRequest?
            var invalidURLError: MockAPIEndpoint.MakeRequestError?
            var otherFailureError: MockAPIEndpoint.MakeRequestError?
            
            switch endpoint.makeRequest() {
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
        
        @Test
        func jsonEncodingFailure() {
            let endpoint: MockAPIEndpoint = .jsonEncodingFailure(encodable: InvalidEncodable())
            var successRequest: URLRequest?
            var jsonEncodingFailureError: MockAPIEndpoint.MakeRequestError?
            var otherFailureError: MockAPIEndpoint.MakeRequestError?
            
            switch endpoint.makeRequest() {
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
