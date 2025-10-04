//
//  URLSessionClientTests.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/6/22.
//

import Testing
import Foundation

@testable import Networking

@Suite
enum URLSessionClientPluginTests {
    
}

extension URLSessionClientPluginTests {
    
    class MockURLSession: URLSessionProtocol {
        enum TestCase {
            case success
            case notHTTPResponse
            case requestFailure(Int)
            case urlSessionError(Error)
            case selfNotExist
        }
        private let testCase: TestCase
        
        init(testCase: TestCase) {
            self.testCase = testCase
        }
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            switch testCase {
            case .success, .selfNotExist:
                return (Data(), makeHTTPURLResponse(request: request, statusCode: 200))
            case .notHTTPResponse:
                return (Data(), URLResponse())
            case .requestFailure(let statusCode):
                return (Data(), makeHTTPURLResponse(request: request, statusCode: statusCode))
            case .urlSessionError(let error):
                throw error
            }
        }
        
        private func makeHTTPURLResponse(request: URLRequest, statusCode: Int) -> HTTPURLResponse {
            return HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        }
    }
}
