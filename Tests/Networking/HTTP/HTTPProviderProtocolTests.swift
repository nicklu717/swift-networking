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
            let provider = TestAPIProvider(mockTaskResult: .success(data))
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
        func jsonDecodingFailure() async throws {
            let data = "{}".data(using: .utf8)!
            let provider = TestAPIProvider(mockTaskResult: .success(data))
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
        
//        @Test
//        func jsonDecodingFailure() async throws {
//            let data = "{}".data(using: .utf8)!
//            let provider = TestAPIProvider(mockTaskResult: .success(data))
//            var successObject: TestObject?
//            var jsonDecodingFailureError: HTTPProviderFetchError?
//            var otherFailureError: HTTPProviderFetchError?
//            
//            let result: FetchResult = await provider.fetchObject(for: .plain())
//            switch result {
//            case .success(let object):
//                successObject = object
//            case .failure(let error):
//                switch error {
//                case .jsonDecodingFailure:
//                    jsonDecodingFailureError = error
//                default:
//                    otherFailureError = error
//                }
//            }
//            
//            #expect(successObject == nil)
//            #expect(jsonDecodingFailureError != nil)
//            #expect(otherFailureError == nil)
//        }
    }
    
    @Suite
    struct FetchObjectPublisherTests {
        
        var cancellables = Set<AnyCancellable>()
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        mutating func success() async {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = TestAPIProvider(mockTaskResult: .success(data))
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
    }
}

extension HTTPProviderProtocolTests {
    
    class TestAPIProvider: HTTPProviderProtocol {
        typealias Endpoint = TestAPIEndpoint
        
        let client: URLSessionClient
        let jsonDecoder: JSONDecoder
        
        init(mockTaskResult: URLSessionClient.TaskResult) {
            self.client = MockURLSessionClient(mockTaskResult: mockTaskResult)
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
