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
    
    @Suite
    struct FetchObjectTests {
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        func success() async throws {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = MockAPIProvider(client: MockURLSessionClient(mockResult: .success(data)))
            var successObject: MockObject?
            var failureError: MockAPIProvider.FetchError?
            
            let result: Result<MockObject, MockAPIProvider.FetchError> = await provider.fetchObject(for: .plain())
            switch result {
            case .success(let object):
                successObject = object
            case .failure(let error):
                failureError = error
            }
            
            #expect(successObject == MockObject(id: mockID, name: mockName))
            #expect(failureError == nil)
        }
        
        @Test
        func jsonDecodingFailure() async throws {
            let data = "{}".data(using: .utf8)!
            let provider = MockAPIProvider(client: MockURLSessionClient(mockResult: .success(data)))
            var successObject: MockObject?
            var jsonDecodingFailureError: MockAPIProvider.FetchError?
            var otherFailureError: MockAPIProvider.FetchError?
            
            let result: Result<MockObject, MockAPIProvider.FetchError> = await provider.fetchObject(for: .plain())
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
            let provider = MockAPIProvider(client: MockURLSessionClient(mockResult: .success(data)))
            var successObject: MockObject?
            var isFinished = false
            var failureError: MockAPIProvider.FetchError?
            
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
            
            #expect(successObject == MockObject(id: mockID, name: mockName))
            #expect(isFinished)
            #expect(failureError == nil)
        }
        
        @Test
        mutating func selfBeingReleased() async {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            var provider: MockAPIProvider? = MockAPIProvider(client: MockURLSessionClient(mockResult: .success(data)))
            var successObject: MockObject?
            var isFinished = false
            var selfBeingReleasedError: MockAPIProvider.FetchError?
            var otherFailureError: MockAPIProvider.FetchError?
            
            await withCheckedContinuation { continuation in
                let publisher: AnyPublisher<MockObject, MockAPIProvider.FetchError> = provider!.fetchObjectPublisher(for: .plain())
                provider = nil
                publisher
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
                        receiveValue: { object in
                            successObject = object
                        }
                    )
                    .store(in: &cancellables)
            }
            
            #expect(successObject == nil)
            #expect(!isFinished)
            #expect(selfBeingReleasedError != nil)
            #expect(otherFailureError == nil)
        }
    }
}

    class MockURLSessionClient: URLSessionClientProtocol {
        let mockResult: Result<Data, URLSessionClient.FetchError>
        
        init(mockResult: Result<Data, URLSessionClient.FetchError>) {
            self.mockResult = mockResult
        }
        
        func fetchData(request: URLRequest) async -> Result<Data, URLSessionClient.FetchError> {
            return mockResult
        }
        
        func fetchDataPublisher(request: URLRequest, resultAfterCancelledHandler: ((Result<Data, Networking.URLSessionClient.FetchError>) -> Void)?) -> AnyPublisher<Data, Networking.URLSessionClient.FetchError> {
            return mockResult.publisher.eraseToAnyPublisher()
        }
    }

extension HTTPProviderTests {
    
    class MockAPIProvider: HTTPProvider<MockAPIEndpoint> {}
    
    struct MockObject: Decodable, Equatable {
        let id: Int
        let name: String
        
        init(id: Int, name: String) {
            self.id = id
            self.name = name
        }
    }
}
