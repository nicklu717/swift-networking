//
//  HTTPProviderProtocol.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/16.
//

import Foundation
import Combine

public enum HTTPProviderFetchError: Error {
    case urlSessionClientError(URLSessionClient.FetchError)
    case makeRequestError(HTTPEndpoint.MakeRequestError)
    case jsonDecodingFailure(Error)
}

public protocol HTTPProviderProtocol {
    associatedtype Endpoint: HTTPEndpoint
    
    var client: URLSessionClientProtocol { get }
    var jsonDecoder: JSONDecoder { get }
    
    typealias FetchResult<T> = Result<T, HTTPProviderFetchError>
    typealias FetchPublisher<T> = AnyPublisher<T, HTTPProviderFetchError>
    
    func fetchObject<T: Decodable>(for endpoint: Endpoint) async -> FetchResult<T>
    func fetchObjectPublisher<T: Decodable>(for endpoint: Endpoint) -> FetchPublisher<T>
}

public extension HTTPProviderProtocol {
    // MARK: - Async
    func fetchObject<T>(for endpoint: Endpoint) async -> FetchResult<T> where T: Decodable {
        return await fetchData(for: endpoint).flatMap { decode(data: $0) }
    }
    
    private func fetchData(for endpoint: Endpoint) async -> FetchResult<Data> {
        return await makeRequest(for: endpoint)
            .asyncFlatMap {
                await client.fetchData(request: $0)
                    .mapError { .urlSessionClientError($0) }
            }
    }
    
    // MARK: - Combine
    func fetchObjectPublisher<T>(for endpoint: Endpoint) -> FetchPublisher<T> where T: Decodable {
        return fetchDataPublisher(for: endpoint)
            .flatMap { decode(data: $0).publisher.eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }
    
    private func fetchDataPublisher(for endpoint: Endpoint) -> FetchPublisher<Data> {
        return makeRequest(for: endpoint).publisher
            .flatMap {
                client.fetchDataPublisher(request: $0, resultAfterCancelledHandler: nil)
                    .mapError { .urlSessionClientError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func makeRequest(for endpoint: Endpoint) -> FetchResult<URLRequest> {
        return endpoint.makeRequest().mapError { .makeRequestError($0) }
    }
    
    private func decode<T>(data: Data) -> FetchResult<T> where T: Decodable {
        do {
            return .success(try jsonDecoder.decode(T.self, from: data))
        } catch {
            return .failure(.jsonDecodingFailure(error))
        }
    }
}
