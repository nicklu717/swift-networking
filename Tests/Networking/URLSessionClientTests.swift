//
//  URLSessionClientTests.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/6/22.
//

import Testing
import Foundation
import Combine

@testable import Networking

@Suite
enum URLSessionClientTests {
    typealias RequestDataError = URLSessionClient.RequestDataError
    
    static let mockURL = URL(string: "https://example.com")!
    
    @Suite
    struct RequestDataTests {
        
        @Test
        func success() async {
            let client = TestURLSessionClient(testCase: .success)
            var successData: Data?
            var failureError: RequestDataError?
            
            switch await client.requestData(url: mockURL) {
            case .success(let data):
                successData = data
            case .failure(let error):
                failureError = error
            }
            
            #expect(successData != nil)
            #expect(failureError == nil)
        }
        
        @Test
        func notHTTPResponse() async {
            let client = TestURLSessionClient(testCase: .notHTTPResponse)
            var successData: Data?
            var notHTTPResponseError: RequestDataError?
            var otherFailureError: RequestDataError?
            
            switch await client.requestData(url: mockURL) {
            case .success(let data):
                successData = data
            case .failure(let error):
                switch error {
                case .notHTTPResponse:
                    notHTTPResponseError = error
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successData == nil)
            #expect(notHTTPResponseError != nil)
            #expect(otherFailureError == nil)
        }
        
        @Test(arguments: [300, 400, 500, 600, 900])
        func requestFailure(statusCode: Int) async throws {
            let client = TestURLSessionClient(testCase: .requestFailure(statusCode))
            var successData: Data?
            var requestFailureStatusCode: Int?
            var otherFailureError: RequestDataError?
            
            switch await client.requestData(url: mockURL) {
            case .success(let data):
                successData = data
            case .failure(let error):
                switch error {
                case .requestFailure(let statusCode, _):
                    requestFailureStatusCode = statusCode
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successData == nil)
            #expect(try #require(requestFailureStatusCode) == statusCode)
            #expect(otherFailureError == nil)
        }
        
        @Test
        func urlSessionError() async throws {
            let mockError = NSError(domain: "mockErrorDomain", code: 999)
            
            let client = TestURLSessionClient(testCase: .urlSessionError(mockError))
            var successData: Data?
            var underlyingURLSessionError: NSError?
            var otherFailureError: RequestDataError?
            
            switch await client.requestData(url: mockURL) {
            case .success(let data):
                successData = data
            case .failure(let error):
                switch error {
                case .urlSessionError(let error):
                    underlyingURLSessionError = error as NSError
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successData == nil)
            #expect(try #require(underlyingURLSessionError) == mockError)
            #expect(otherFailureError == nil)
        }
        
        @Test
        func urlSessionTaskCancelled() async throws {
            let client = URLSessionClient(urlSession: URLSession.shared)
            var successData: Data?
            var urlSessionTaskCancelledError: NSError?
            var otherFailureError: RequestDataError?
            
            let task = Task {
                await client.requestData(url: mockURL)
            }
            task.cancel()
            switch await task.value {
            case .success(let data):
                successData = data
            case .failure(let error):
                switch error {
                case .urlSessionError(let error):
                    urlSessionTaskCancelledError = error as NSError
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successData == nil)
            #expect(try #require(urlSessionTaskCancelledError).code == -999)
            #expect(otherFailureError == nil)
        }
    }
    
    @Suite
    struct RequestDataPublisherTests {
        
        private var cancellable: AnyCancellable?
        
        @Test
        mutating func success() async {
            let client = TestURLSessionClient(testCase: .success)
            var successData: Data?
            var failureError: RequestDataError?
            var isFinished = false
            
            await withCheckedContinuation { continuation in
                cancellable = client.requestDataPublisher(url: mockURL, resultAfterCancelledHandler: nil)
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                failureError = error
                            }
                            continuation.resume()
                        },
                        receiveValue: {
                            successData = $0
                        }
                    )
            }
            
            #expect(successData != nil)
            #expect(failureError == nil)
            #expect(isFinished)
        }
        
        @Test
        mutating func notHTTPResponse() async {
            let client = TestURLSessionClient(testCase: .notHTTPResponse)
            var successData: Data?
            var notHTTPResponseError: RequestDataError?
            var otherFailureError: RequestDataError?
            var isFinished = false
            
            await withCheckedContinuation { continuation in
                cancellable = client.requestDataPublisher(url: mockURL, resultAfterCancelledHandler: nil)
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                switch error {
                                case .notHTTPResponse:
                                    notHTTPResponseError = error
                                default:
                                    otherFailureError = error
                                }
                            }
                            continuation.resume()
                        },
                        receiveValue: {
                            successData = $0
                        }
                    )
            }
            
            #expect(successData == nil)
            #expect(notHTTPResponseError != nil)
            #expect(otherFailureError == nil)
            #expect(!isFinished)
        }
        
        @Test(arguments: [300, 400, 500, 600, 900])
        mutating func requestFailure(statusCode: Int) async throws {
            let client = TestURLSessionClient(testCase: .requestFailure(statusCode))
            var successData: Data?
            var requestFailureStatusCode: Int?
            var otherFailureError: RequestDataError?
            var isFinished = false
            
            await withCheckedContinuation { continuation in
                cancellable = client.requestDataPublisher(url: mockURL, resultAfterCancelledHandler: nil)
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                switch error {
                                case .requestFailure(let statusCode, _):
                                    requestFailureStatusCode = statusCode
                                default:
                                    otherFailureError = error
                                }
                            }
                            continuation.resume()
                        },
                        receiveValue: {
                            successData = $0
                        }
                    )
            }
            
            #expect(successData == nil)
            #expect(try #require(requestFailureStatusCode) == statusCode)
            #expect(otherFailureError == nil)
            #expect(!isFinished)
        }
        
        @Test
        mutating func urlSessionError() async throws {
            let mockError = NSError(domain: "mockErrorDomain", code: 999)
            
            let client = TestURLSessionClient(testCase: .urlSessionError(mockError))
            var successData: Data?
            var underlyingURLSessionError: NSError?
            var otherFailureError: RequestDataError?
            var isFinished = false
            
            await withCheckedContinuation { continuation in
                cancellable = client.requestDataPublisher(url: mockURL, resultAfterCancelledHandler: nil)
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                switch error {
                                case .urlSessionError(let error):
                                    underlyingURLSessionError = error as NSError
                                default:
                                    otherFailureError = error
                                }
                            }
                            continuation.resume()
                        },
                        receiveValue: {
                            successData = $0
                        }
                    )
            }
            
            #expect(successData == nil)
            #expect(try #require(underlyingURLSessionError) == mockError)
            #expect(otherFailureError == nil)
            #expect(!isFinished)
        }
        
        @Test
        mutating func urlSessionTaskCancelled() async throws {
            let client = URLSessionClient(urlSession: URLSession.shared)
            var successData: Data?
            var urlSessionTaskCancelledError: NSError?
            var otherFailureError: RequestDataError?
            var isFinished = false
            
            await withCheckedContinuation { continuation in
                let resultAfterCancelledHandler: (Result<Data, RequestDataError>) -> Void = {
                    switch $0 {
                    case .success(let data):
                        successData = data
                    case .failure(let error):
                        switch error {
                        case .urlSessionError(let error):
                            urlSessionTaskCancelledError = error as NSError
                        default:
                            otherFailureError = error
                        }
                    }
                    continuation.resume()
                }
                cancellable = client.requestDataPublisher(url: mockURL, resultAfterCancelledHandler: resultAfterCancelledHandler)
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                otherFailureError = error
                            }
                        },
                        receiveValue: {
                            successData = $0
                        }
                    )
                cancellable?.cancel()
            }
            
            #expect(successData == nil)
            #expect(try #require(urlSessionTaskCancelledError).code == -999)
            #expect(otherFailureError == nil)
            #expect(!isFinished)
        }
        
        @Test
        mutating func selfBeingReleased() async {
            var client: URLSessionClient? = TestURLSessionClient(testCase: .selfBeingReleased)
            var successData: Data?
            var selfBeingReleasedError: RequestDataError?
            var otherFailureError: RequestDataError?
            var isFinished = false
            
            await withCheckedContinuation { continuation in
                let publisher = client!.requestDataPublisher(url: mockURL, resultAfterCancelledHandler: nil)
                client = nil
                cancellable = publisher
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                switch error {
                                case .selfBeingReleased:
                                    selfBeingReleasedError = error
                                default:
                                    otherFailureError = error
                                }
                            }
                            continuation.resume()
                        },
                        receiveValue: {
                            successData = $0
                        }
                    )
            }
            
            #expect(successData == nil)
            #expect(selfBeingReleasedError != nil)
            #expect(otherFailureError == nil)
            #expect(!isFinished)
        }
    }
}

extension URLSessionClientTests {
    
    class TestURLSessionClient: URLSessionClient {
        
        init(testCase: MockURLSession.TestCase) {
            super.init(urlSession: MockURLSession(testCase: testCase))
        }
        
        class MockURLSession: URLSessionProtocol {
            enum TestCase {
                case success
                case notHTTPResponse
                case requestFailure(Int)
                case urlSessionError(Error)
                case selfBeingReleased
            }
            private let testCase: TestCase
            
            init(testCase: TestCase) {
                self.testCase = testCase
            }
            
            func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                switch testCase {
                case .success, .selfBeingReleased:
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
}
