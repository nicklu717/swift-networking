//
//  HTTPProviderTests.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/17.
//

import Testing
import Foundation
import Combine

@testable import Networking

@Suite
struct HTTPProviderTests {
    typealias TestAPIProvider = HTTPProvider<TestAPIEndpoint>
    typealias RequestError = TestAPIProvider.RequestError
    
    @Suite
    struct RequestObjectTests {
        typealias RequestTestObjectResult = TestAPIProvider.RequestResult<TestObject>
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        func success() async {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = TestAPIProvider(
                client: MockURLSessionClient(testCase: .success(data)),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var failureError: RequestError?
            
            let result: RequestTestObjectResult = await provider.requestObject(.plain())
            switch result {
            case .success(let object):
                successObject = object
            case .failure(let error):
                failureError = error
            }
            
            #expect(successObject == TestObject(id: mockID, name: mockName))
            #expect(failureError == nil)
        }
        
        @Test
        func urlSessionClientError() async {
            let provider = TestAPIProvider(
                client: MockURLSessionClient(testCase: .urlSessionClientError),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var urlSessionClientError: RequestError?
            var otherFailureError: RequestError?
            
            let result: RequestTestObjectResult = await provider.requestObject(.plain())
            switch result {
            case .success(let object):
                successObject = object
            case .failure(let error):
                switch error {
                case .urlSessionClientError:
                    urlSessionClientError = error
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successObject == nil)
            #expect(urlSessionClientError != nil)
            #expect(otherFailureError == nil)
        }
        
        @Test
        func makeRequestError() async {
            let provider = TestAPIProvider(
                client: MockURLSessionClient(testCase: .success(Data())),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var makeRequestError: RequestError?
            var otherFailureError: RequestError?
            
            let result: RequestTestObjectResult = await provider.requestObject(.invalidURL())
            switch result {
            case .success(let object):
                successObject = object
            case .failure(let error):
                switch error {
                case .makeRequestError:
                    makeRequestError = error
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successObject == nil)
            #expect(makeRequestError != nil)
            #expect(otherFailureError == nil)
        }
        
        @Test
        func jsonDecodingFailure() async {
            let provider = TestAPIProvider(
                client: MockURLSessionClient(testCase: .jsonDecodingFailure(Data())),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var jsonDecodingFailureError: RequestError?
            var otherFailureError: RequestError?
            
            let result: RequestTestObjectResult = await provider.requestObject(.plain())
            switch result {
            case .success(let object):
                successObject = object
            case .failure(let error):
                switch error {
                case .jsonDecodingFailure:
                    jsonDecodingFailureError = error
                default:
                    otherFailureError = error
                }
            }
            
            #expect(successObject == nil)
            #expect(jsonDecodingFailureError != nil)
            #expect(otherFailureError == nil)
        }
    }
    
    @Suite
    struct RequestPublisherTests {
        
        var cancellables = Set<AnyCancellable>()
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        mutating func success() async {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = TestAPIProvider(
                client: MockURLSessionClient(testCase: .success(data)),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var isFinished = false
            var failureError: RequestError?
            
            await withCheckedContinuation { continuation in
                provider.requestObjectPublisher(.plain())
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
                        receiveValue: { object in
                            successObject = object
                        }
                    )
                    .store(in: &cancellables)
            }
            
            #expect(successObject == TestObject(id: mockID, name: mockName))
            #expect(isFinished)
            #expect(failureError == nil)
        }
        
        @Test
        mutating func urlSessionClientError() async {
            let provider = TestAPIProvider(
                client: MockURLSessionClient(testCase: .urlSessionClientError),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var isFinished = false
            var urlSessionClientError: RequestError?
            var otherFailureError: RequestError?
            
            await withCheckedContinuation { continuation in
                provider.requestObjectPublisher(.plain())
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                switch error {
                                case .urlSessionClientError:
                                    urlSessionClientError = error
                                default:
                                    otherFailureError = error
                                }
                            }
                            continuation.resume()
                        },
                        receiveValue: { object in
                            successObject = object
                        }
                    )
                    .store(in: &cancellables)
            }
            
            #expect(successObject == nil)
            #expect(!isFinished)
            #expect(urlSessionClientError != nil)
            #expect(otherFailureError == nil)
        }
        
        @Test
        mutating func makeRequestError() async {
            let provider = TestAPIProvider(
                client: MockURLSessionClient(testCase: .success(Data())),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var isFinished = false
            var makeRequestError: RequestError?
            var otherFailureError: RequestError?
            
            await withCheckedContinuation { continuation in
                provider.requestObjectPublisher(.invalidURL())
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                switch error {
                                case .makeRequestError:
                                    makeRequestError = error
                                default:
                                    otherFailureError = error
                                }
                            }
                            continuation.resume()
                        },
                        receiveValue: { object in
                            successObject = object
                        }
                    )
                    .store(in: &cancellables)
            }
            
            #expect(successObject == nil)
            #expect(!isFinished)
            #expect(makeRequestError != nil)
            #expect(otherFailureError == nil)
        }
        
        @Test
        mutating func jsonDecodingFailure() async {
            let provider = TestAPIProvider(
                client: MockURLSessionClient(testCase: .jsonDecodingFailure(Data())),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var isFinished = false
            var jsonDecodingFailure: RequestError?
            var otherFailureError: RequestError?
            
            await withCheckedContinuation { continuation in
                provider.requestObjectPublisher(.plain())
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                switch error {
                                case .jsonDecodingFailure:
                                    jsonDecodingFailure = error
                                default:
                                    otherFailureError = error
                                }
                            }
                            continuation.resume()
                        },
                        receiveValue: { object in
                            successObject = object
                        }
                    )
                    .store(in: &cancellables)
            }
            
            #expect(successObject == nil)
            #expect(!isFinished)
            #expect(jsonDecodingFailure != nil)
            #expect(otherFailureError == nil)
        }
        
        @Test
        mutating func selfNotExist() async {
            var provider: TestAPIProvider? = TestAPIProvider(
                client: MockURLSessionClient(testCase: .success(Data())),
                jsonDecoder: JSONDecoder()
            )
            var successObject: TestObject?
            var isFinished = false
            var selfNotExistError: RequestError?
            var otherFailureError: RequestError?
            
            await withCheckedContinuation { continuation in
                let publisher: TestAPIProvider.RequestPublisher<TestObject> = provider!.requestObjectPublisher(.plain())
                provider = nil
                publisher
                    .sink(
                        receiveCompletion: {
                            switch $0 {
                            case .finished:
                                isFinished = true
                            case .failure(let error):
                                switch error {
                                case .selfNotExist:
                                    selfNotExistError = error
                                default:
                                    otherFailureError = error
                                }
                            }
                            continuation.resume()
                        },
                        receiveValue: { object in
                            successObject = object
                        }
                    )
                    .store(in: &cancellables)
            }
            
            #expect(successObject == nil)
            #expect(!isFinished)
            #expect(selfNotExistError != nil)
            #expect(otherFailureError == nil)
        }
    }
}

extension HTTPProviderTests {
    
    class MockURLSessionClient: URLSessionClient {
        enum TestCase {
            case success(Data)
            case urlSessionClientError
            case jsonDecodingFailure(Data)
        }
        let testCase: TestCase
        
        init(testCase: TestCase) {
            self.testCase = testCase
            super.init(urlSession: DummyURLSession())
        }
        
        override func requestData(request: URLRequest) async -> RequestResult {
            switch testCase {
            case .success(let data), .jsonDecodingFailure(let data):
                return .success(data)
            case .urlSessionClientError:
                return .failure(.selfNotExist)
            }
        }
        
        class DummyURLSession: URLSessionProtocol {
            func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                return (Data(), URLResponse())
            }
        }
    }
}
