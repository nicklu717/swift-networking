//
//  HTTPProviderProtocol.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/16.
//

import Foundation
import Combine

public enum HTTPProviderRequestError: Error {
    case urlSessionClientError(URLSessionClient.RequestError)
    case makeRequestError(HTTPEndpoint.MakeRequestError)
    case jsonDecodingFailure(Error)
}

public protocol HTTPProviderProtocol {
    associatedtype Endpoint: HTTPEndpoint
    
    typealias RequestError = HTTPProviderRequestError
    typealias RequestResult<T> = Result<T, HTTPProviderRequestError>
    typealias RequestPublisher<T> = AnyPublisher<T, HTTPProviderRequestError>
    
    var client: URLSessionClient { get }
    var jsonDecoder: JSONDecoder { get }
    
    func requestObject<T: Decodable>(for endpoint: Endpoint) async -> RequestResult<T>
    func requestObjectPublisher<T: Decodable>(for endpoint: Endpoint) -> RequestPublisher<T>
}

public extension HTTPProviderProtocol {
    // MARK: - Async
    func requestObject<T>(for endpoint: Endpoint) async -> RequestResult<T> where T: Decodable {
        return await requestData(for: endpoint).flatMap { decode(data: $0) }
    }
    
    private func requestData(for endpoint: Endpoint) async -> RequestResult<Data> {
        return await makeRequest(for: endpoint)
            .asyncFlatMap {
                await client.requestData(request: $0)
                    .mapError { .urlSessionClientError($0) }
            }
    }
    
    // MARK: - Combine
    func requestObjectPublisher<T>(for endpoint: Endpoint) -> RequestPublisher<T> where T: Decodable {
        return requestDataPublisher(for: endpoint)
            .flatMap { decode(data: $0).publisher.eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    private func requestDataPublisher(for endpoint: Endpoint) -> RequestPublisher<Data> {
        return makeRequest(for: endpoint).publisher
            .flatMap {
                client.requestDataPublisher(request: $0, resultAfterCancelledHandler: nil)
                    .mapError { .urlSessionClientError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func makeRequest(for endpoint: Endpoint) -> RequestResult<URLRequest> {
        return endpoint.makeRequest().mapError { .makeRequestError($0) }
    }
    
    private func decode<T>(data: Data) -> RequestResult<T> where T: Decodable {
        do {
            return .success(try jsonDecoder.decode(T.self, from: data))
        } catch {
            return .failure(.jsonDecodingFailure(error))
        }
    }
}
