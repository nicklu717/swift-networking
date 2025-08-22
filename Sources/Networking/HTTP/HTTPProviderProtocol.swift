//
//  HTTPProviderProtocol.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/16.
//

import Foundation
import Combine
import Utilities

public enum HTTPProviderRequestObjectError: Error {
    case urlSessionClientError(URLSessionClient.RequestDataError)
    case makeRequestError(HTTPEndpoint.MakeRequestError)
    case jsonDecodingFailure(Error)
    case custom(String, Error?)
}

public protocol HTTPProviderProtocol {
    associatedtype Endpoint: HTTPEndpoint
    
    typealias RequestObjectError = HTTPProviderRequestObjectError
    typealias RequestObjectResult<T> = Result<T, RequestObjectError>
    typealias RequestObjectPublisher<T> = AnyPublisher<T, RequestObjectError>
    
    var client: URLSessionClient { get }
    var jsonDecoder: JSONDecoder { get }
    
    func requestObject<T: Decodable>(for endpoint: Endpoint) async -> RequestObjectResult<T>
    func requestObjectPublisher<T: Decodable>(for endpoint: Endpoint) -> RequestObjectPublisher<T>
    func requestData(for endpoint: Endpoint) async -> RequestObjectResult<Data>
    func requestDataPublisher(for endpoint: Endpoint) -> RequestObjectPublisher<Data>
}

public extension HTTPProviderProtocol {
    // MARK: - Async
    func requestObject<T>(for endpoint: Endpoint) async -> RequestObjectResult<T> where T: Decodable {
        return await requestData(for: endpoint).flatMap { decode(data: $0) }
    }
    
    func requestData(for endpoint: Endpoint) async -> RequestObjectResult<Data> {
        return await makeRequest(for: endpoint)
            .asyncFlatMap {
                await client.requestData(request: $0)
                    .mapError { .urlSessionClientError($0) }
            }
    }
    
    // MARK: - Combine
    func requestObjectPublisher<T>(for endpoint: Endpoint) -> RequestObjectPublisher<T> where T: Decodable {
        return requestDataPublisher(for: endpoint)
            .flatMap { decode(data: $0).publisher.eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    func requestDataPublisher(for endpoint: Endpoint) -> RequestObjectPublisher<Data> {
        return makeRequest(for: endpoint).publisher
            .flatMap {
                client.requestDataPublisher(request: $0, resultAfterCancelledHandler: nil)
                    .mapError { .urlSessionClientError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func makeRequest(for endpoint: Endpoint) -> RequestObjectResult<URLRequest> {
        return endpoint.makeRequest().mapError { .makeRequestError($0) }
    }
    
    private func decode<T>(data: Data) -> RequestObjectResult<T> where T: Decodable {
        do {
            return .success(try jsonDecoder.decode(T.self, from: data))
        } catch {
            return .failure(.jsonDecodingFailure(error))
        }
    }
}
