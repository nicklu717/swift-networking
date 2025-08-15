//
//  HTTPProviderProtocolTests.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/17.
//

import Testing
import Foundation
import Combine

@testable import Networking

@Suite
struct HTTPProviderProtocolTests {
    
    @Suite
    struct FetchObjectTests {
        typealias FetchResult = TestAPIProvider.FetchResult<TestObject>
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        func success() async throws {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = TestAPIProvider(testCase: .success(data))
            var successObject: TestObject?
            var failureError: HTTPProviderFetchError?
            
            let result: FetchResult = await provider.fetchObject(for: .plain())
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
        func urlSessionClientError() async throws {
            let provider = TestAPIProvider(testCase: .urlSessionClientError)
            var successObject: TestObject?
            var urlSessionClientError: HTTPProviderFetchError?
            var otherFailureError: HTTPProviderFetchError?
            
            let result: FetchResult = await provider.fetchObject(for: .plain())
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
        func makeRequestError() async throws {
            let provider = TestAPIProvider(testCase: .makeRequestError)
            var successObject: TestObject?
            var makeRequestError: HTTPProviderFetchError?
            var otherFailureError: HTTPProviderFetchError?
            
            let result: FetchResult = await provider.fetchObject(for: .invalidURL())
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
        func jsonDecodingFailure() async throws {
            let provider = TestAPIProvider(testCase: .jsonDecodingFailure(Data()))
            var successObject: TestObject?
            var jsonDecodingFailureError: HTTPProviderFetchError?
            var otherFailureError: HTTPProviderFetchError?
            
            let result: FetchResult = await provider.fetchObject(for: .plain())
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
    struct FetchObjectPublisherTests {
        
        var cancellables = Set<AnyCancellable>()
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        mutating func success() async {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = TestAPIProvider(testCase: .success(data))
            var successObject: TestObject?
            var isFinished = false
            var failureError: HTTPProviderFetchError?
            
            await withCheckedContinuation { continuation in
                provider.fetchObjectPublisher(for: .plain())
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
        mutating func urlSessionClientError() async throws {
            let provider = TestAPIProvider(testCase: .urlSessionClientError)
            var successObject: TestObject?
            var isFinished = false
            var urlSessionClientError: HTTPProviderFetchError?
            var otherFailureError: HTTPProviderFetchError?
            
            await withCheckedContinuation { continuation in
                provider.fetchObjectPublisher(for: .plain())
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
        mutating func makeRequestError() async throws {
            let provider = TestAPIProvider(testCase: .makeRequestError)
            var successObject: TestObject?
            var isFinished = false
            var makeRequestError: HTTPProviderFetchError?
            var otherFailureError: HTTPProviderFetchError?
            
            await withCheckedContinuation { continuation in
                provider.fetchObjectPublisher(for: .invalidURL())
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
        mutating func jsonDecodingFailure() async throws {
            let provider = TestAPIProvider(testCase: .jsonDecodingFailure(Data()))
            var successObject: TestObject?
            var isFinished = false
            var jsonDecodingFailure: HTTPProviderFetchError?
            var otherFailureError: HTTPProviderFetchError?
            
            await withCheckedContinuation { continuation in
                provider.fetchObjectPublisher(for: .plain())
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
    }
}

extension HTTPProviderProtocolTests {
    
    class TestAPIProvider: HTTPProviderProtocol {
        typealias Endpoint = TestAPIEndpoint
        
        let client: URLSessionClient
        let jsonDecoder: JSONDecoder
        
        enum TestCase {
            case success(Data)
            case urlSessionClientError
            case makeRequestError
            case jsonDecodingFailure(Data)
        }
        
        init(testCase: TestCase) {
            switch testCase {
            case .success(let data), .jsonDecodingFailure(let data):
                self.client = MockURLSessionClient(mockTaskResult: .success(data))
            case .urlSessionClientError:
                self.client = MockURLSessionClient(mockTaskResult: .failure(.selfBeingReleased))
            case .makeRequestError:
                self.client = DummyURLSessionClient()
            }
            self.jsonDecoder = JSONDecoder()
        }
        
        class MockURLSessionClient: URLSessionClient {
            let mockTaskResult: TaskResult
            
            init(mockTaskResult: TaskResult) {
                self.mockTaskResult = mockTaskResult
                super.init(urlSession: DummyURLSession())
            }
            
            override func fetchData(request: URLRequest) async -> TaskResult {
                return mockTaskResult
            }
            
            override func fetchDataPublisher(request: URLRequest, resultAfterCancelledHandler: ((Result<Data, Networking.URLSessionClient.FetchError>) -> Void)?) -> TaskPublisher {
                return mockTaskResult.publisher.eraseToAnyPublisher()
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
