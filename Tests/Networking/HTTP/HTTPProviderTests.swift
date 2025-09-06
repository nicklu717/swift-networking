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
    typealias RequestObjectError = TestAPIProvider.RequestObjectError
    
    @Suite
    struct RequestObjectTests {
        typealias RequestTestObjectResult = TestAPIProvider.RequestObjectResult<TestObject>
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        func success() async {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = TestAPIProvider(testCase: .success(data))
            var successObject: TestObject?
            var failureError: RequestObjectError?
            
            let result: RequestTestObjectResult = await provider.requestObject(for: .plain())
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
            let provider = TestAPIProvider(testCase: .urlSessionClientError)
            var successObject: TestObject?
            var urlSessionClientError: RequestObjectError?
            var otherFailureError: RequestObjectError?
            
            let result: RequestTestObjectResult = await provider.requestObject(for: .plain())
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
            let provider = TestAPIProvider(testCase: .makeRequestError)
            var successObject: TestObject?
            var makeRequestError: RequestObjectError?
            var otherFailureError: RequestObjectError?
            
            let result: RequestTestObjectResult = await provider.requestObject(for: .invalidURL())
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
            let provider = TestAPIProvider(testCase: .jsonDecodingFailure(Data()))
            var successObject: TestObject?
            var jsonDecodingFailureError: RequestObjectError?
            var otherFailureError: RequestObjectError?
            
            let result: RequestTestObjectResult = await provider.requestObject(for: .plain())
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
    struct RequestObjectPublisherTests {
        
        var cancellables = Set<AnyCancellable>()
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        mutating func success() async {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = TestAPIProvider(testCase: .success(data))
            var successObject: TestObject?
            var isFinished = false
            var failureError: RequestObjectError?
            
            await withCheckedContinuation { continuation in
                provider.requestObjectPublisher(for: .plain())
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
            let provider = TestAPIProvider(testCase: .urlSessionClientError)
            var successObject: TestObject?
            var isFinished = false
            var urlSessionClientError: RequestObjectError?
            var otherFailureError: RequestObjectError?
            
            await withCheckedContinuation { continuation in
                provider.requestObjectPublisher(for: .plain())
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
            let provider = TestAPIProvider(testCase: .makeRequestError)
            var successObject: TestObject?
            var isFinished = false
            var makeRequestError: RequestObjectError?
            var otherFailureError: RequestObjectError?
            
            await withCheckedContinuation { continuation in
                provider.requestObjectPublisher(for: .invalidURL())
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
            let provider = TestAPIProvider(testCase: .jsonDecodingFailure(Data()))
            var successObject: TestObject?
            var isFinished = false
            var jsonDecodingFailure: RequestObjectError?
            var otherFailureError: RequestObjectError?
            
            await withCheckedContinuation { continuation in
                provider.requestObjectPublisher(for: .plain())
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
            var provider: TestAPIProvider? = TestAPIProvider(testCase: .success(Data()))
            var successObject: TestObject?
            var isFinished = false
            var selfNotExistError: RequestObjectError?
            var otherFailureError: RequestObjectError?
            
            await withCheckedContinuation { continuation in
                let publisher: TestAPIProvider.RequestObjectPublisher<TestObject> = provider!.requestObjectPublisher(for: .plain())
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
    
    class TestAPIProvider: HTTPProvider<TestAPIEndpoint> {
        enum TestCase {
            case success(Data)
            case urlSessionClientError
            case makeRequestError
            case jsonDecodingFailure(Data)
        }
        
        init(testCase: TestCase) {
            let jsonDecoder = JSONDecoder()
            switch testCase {
            case .success(let data), .jsonDecodingFailure(let data):
                super.init(
                    client: MockURLSessionClient(mockResult: .success(data)),
                    jsonDecoder: jsonDecoder
                )
            case .urlSessionClientError:
                super.init(
                    client: MockURLSessionClient(mockResult: .failure(.selfNotExist)),
                    jsonDecoder: jsonDecoder
                )
            case .makeRequestError:
                super.init(
                    client: DummyURLSessionClient(),
                    jsonDecoder: jsonDecoder
                )
            }
        }
        
        class MockURLSessionClient: URLSessionClient {
            let mockResult: RequestDataResult
            
            init(mockResult: RequestDataResult) {
                self.mockResult = mockResult
                super.init(urlSession: DummyURLSession())
            }
            
            override func requestData(request: URLRequest) async -> RequestDataResult {
                return mockResult
            }
            
            override func requestDataPublisher(
                request: URLRequest,
                resultAfterCancelledHandler: ((RequestDataResult) -> Void)?
            ) -> RequestDataPublisher {
                return mockResult.publisher.eraseToAnyPublisher()
            }
            
            class DummyURLSession: URLSessionProtocol {
                func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                    return (Data(), URLResponse())
                }
            }
        }
        
        class DummyURLSessionClient: URLSessionClient {
            init() {
                super.init(urlSession: DummyURLSession())
            }
            
            class DummyURLSession: URLSessionProtocol {
                func data(for request: URLRequest) async throws -> (Data, URLResponse) {
                    return (Data(), URLResponse())
                }
            }
        }
    }
    
    struct TestObject: Decodable, Equatable {
        let id: Int
        let name: String
        
        init(id: Int, name: String) {
            self.id = id
            self.name = name
        }
    }
}
