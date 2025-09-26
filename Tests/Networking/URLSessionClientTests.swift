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
            let client = URLSessionClient(urlSession: MockURLSession(testCase: .success))
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
            let client = URLSessionClient(urlSession: MockURLSession(testCase: .notHTTPResponse))
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
        
        @Test(arguments: [
            (400, URLSessionClient.HTTPResponseStatus.Kind.clientError),
            (500, URLSessionClient.HTTPResponseStatus.Kind.serverError),
            (900, URLSessionClient.HTTPResponseStatus.Kind.invalid)
        ])
        func requestFailure(statusCode: Int, expectedStatusKind: URLSessionClient.HTTPResponseStatus.Kind) async throws {
            let client = URLSessionClient(urlSession: MockURLSession(testCase: .requestFailure(statusCode)))
            var successData: Data?
            var requestFailureStatus: URLSessionClient.HTTPResponseStatus?
            var otherFailureError: RequestDataError?
            
            switch await client.requestData(url: mockURL) {
            case .success(let data):
                successData = data
            case .failure(let error):
                switch error {
                case .requestFailure(let status, _):
                    requestFailureStatus = status
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successData == nil)
            #expect(try #require(requestFailureStatus).kind == expectedStatusKind)
            #expect(otherFailureError == nil)
        }
        
        @Test
        func urlSessionError() async throws {
            let mockError = NSError(domain: "mockErrorDomain", code: 999)
            
            let client = URLSessionClient(urlSession: MockURLSession(testCase: .urlSessionError(mockError)))
            var successData: Data?
            var underlyingURLSessionError: NSError?
            var otherFailureError: RequestDataError?
            
            switch await client.requestData(url: mockURL) {
            case .success(let data):
                successData = data
            case .failure(let error):
                switch error {
                case .unexpectedURLSessionError(let error):
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
            var urlSessionTaskCancelledError: URLError?
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
                    urlSessionTaskCancelledError = error
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successData == nil)
            #expect(try #require(urlSessionTaskCancelledError).code == .cancelled)
            #expect(otherFailureError == nil)
        }
    }
    
    @Suite
    struct RequestPublisherTests {
        
        private var cancellable: AnyCancellable?
        
        @Test
        mutating func success() async {
            let client = URLSessionClient(urlSession: MockURLSession(testCase: .success))
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
            let client = URLSessionClient(urlSession: MockURLSession(testCase: .notHTTPResponse))
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
        
        @Test(arguments: [
            (400, URLSessionClient.HTTPResponseStatus.Kind.clientError),
            (500, URLSessionClient.HTTPResponseStatus.Kind.serverError),
            (900, URLSessionClient.HTTPResponseStatus.Kind.invalid)
        ])
        mutating func requestFailure(statusCode: Int, expectedStatusKind: URLSessionClient.HTTPResponseStatus.Kind) async throws {
            let client = URLSessionClient(urlSession: MockURLSession(testCase: .requestFailure(statusCode)))
            var successData: Data?
            var requestFailureStatus: URLSessionClient.HTTPResponseStatus?
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
                                case .requestFailure(let status, _):
                                    requestFailureStatus = status
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
            #expect(try #require(requestFailureStatus).kind == expectedStatusKind)
            #expect(otherFailureError == nil)
            #expect(!isFinished)
        }
        
        @Test
        mutating func urlSessionError() async throws {
            let mockError = NSError(domain: "mockErrorDomain", code: 999)
            
            let client = URLSessionClient(urlSession: MockURLSession(testCase: .urlSessionError(mockError)))
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
                                case .unexpectedURLSessionError(let error):
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
            var urlSessionTaskCancelledError: URLError?
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
                            urlSessionTaskCancelledError = error
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
            #expect(try #require(urlSessionTaskCancelledError).code == .cancelled)
            #expect(otherFailureError == nil)
            #expect(!isFinished)
        }
        
        @Test
        mutating func selfNotExist() async {
            var client: URLSessionClient? = URLSessionClient(urlSession: MockURLSession(testCase: .selfNotExist))
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
                                case .selfNotExist:
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
