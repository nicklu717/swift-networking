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
struct HTTPProviderTests {
    
    @Suite
    struct FetchObjectTests {
        
        let mockID = 1
        let mockName = "Test"
        
        @Test
        func success() async throws {
            let data = "{\"id\": \(mockID), \"name\": \"\(mockName)\"}".data(using: .utf8)!
            let provider = MockAPIProvider(client: MockURLSessionClient(mockResult: .success(data)), jsonDecoder: JSONDecoder())
            var successObject: MockObject?
            var failureError: HTTPProviderFetchError?
            
            let result: Result<MockObject, HTTPProviderFetchError> = await provider.fetchObject(for: .plain())
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
            let provider = MockAPIProvider(client: MockURLSessionClient(mockResult: .success(data)), jsonDecoder: JSONDecoder())
            var successObject: MockObject?
            var jsonDecodingFailureError: HTTPProviderFetchError?
            var otherFailureError: HTTPProviderFetchError?
            
            let result: Result<MockObject, HTTPProviderFetchError> = await provider.fetchObject(for: .plain())
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
            let provider = MockAPIProvider(client: MockURLSessionClient(mockResult: .success(data)), jsonDecoder: JSONDecoder())
            var successObject: MockObject?
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
            
            #expect(successObject == MockObject(id: mockID, name: mockName))
            #expect(isFinished)
            #expect(failureError == nil)
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
    
    class MockAPIProvider: HTTPProviderProtocol {
        typealias Endpoint = MockAPIEndpoint
        
        let client: URLSessionClientProtocol
        let jsonDecoder: JSONDecoder
        
        init(client: URLSessionClientProtocol, jsonDecoder: JSONDecoder) {
            self.client = client
            self.jsonDecoder = jsonDecoder
        }
    }
//    class MockAPIProvider: HTTPProvider<MockAPIEndpoint> {}
    
    struct MockObject: Decodable, Equatable {
        let id: Int
        let name: String
        
        init(id: Int, name: String) {
            self.id = id
            self.name = name
        }
    }
}
