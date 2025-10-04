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
struct URLSessionClientPluginTests {
    
    @Test
    func success() async {
        let mockURLRequest = URLRequest(url: URL(string: "Modified")!)
        let mockPlugin = MockPlugin(mockURLRequest: mockURLRequest)
        let client = URLSessionClient(urlSession: MockURLSession(mockResult: .success(())), plugins: [mockPlugin])
        switch await client.requestData(url: URL(string: "Origin")!) {
        case .success:
            #expect(mockPlugin.willSendRequest == mockURLRequest)
            #expect(mockPlugin.didReceiveDataRequest == mockURLRequest)
            #expect(mockPlugin.didReceiveError == nil)
        case .failure:
            #expect(Bool(false))
        }
    }
    
    @Test
    func failure() async {
        let mockError = URLError(.unknown)
        let mockURLRequest = URLRequest(url: URL(string: "Modified")!)
        let mockPlugin = MockPlugin(mockURLRequest: mockURLRequest)
        let client = URLSessionClient(urlSession: MockURLSession(mockResult: .failure(mockError)), plugins: [mockPlugin])
        switch await client.requestData(url: URL(string: "Origin")!) {
        case .success:
            #expect(Bool(false))
        case .failure:
            #expect(mockPlugin.willSendRequest == mockURLRequest)
            #expect(mockPlugin.didReceiveDataRequest == nil)
            #expect(mockPlugin.didReceiveError == mockError)
        }
    }
}

extension URLSessionClientPluginTests {
    
    class MockPlugin: URLSessionClient.Plugin {
        private let mockURLRequest: URLRequest
        
        private(set) var willSendRequest: URLRequest?
        private(set) var didReceiveDataRequest: URLRequest?
        private(set) var didReceiveError: URLError?
        
        init(mockURLRequest: URLRequest) {
            self.mockURLRequest = mockURLRequest
        }
        
        override func modify(request: URLRequest) -> URLRequest {
            return mockURLRequest
        }
        
        override func willSend(request: URLRequest) {
            willSendRequest = request
        }
        
        override func didReceive(data: Data, response: URLResponse, request: URLRequest) {
            didReceiveDataRequest = request
        }
        
        override func didReceive(error: URLError, request: URLRequest) {
            didReceiveError = error
        }
    }
    
    class MockURLSession: URLSessionProtocol {
        private let mockResult: Result<Void, URLError>
        
        init(mockResult: Result<Void, URLError>) {
            self.mockResult = mockResult
        }
        
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            try mockResult
                .map { (Data(), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!) }
                .get()
        }
    }
}
