//
//  HTTPProvider.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/16.
//

import Foundation
import Combine

open class HTTPProvider<Endpoint> where Endpoint: HTTPEndpoint {
    public typealias FetchResult<T> = Result<T, FetchError>
    public typealias FetchPublisher<T> = AnyPublisher<T, FetchError>
    
    private let client: URLSessionClientProtocol
    
    public init(client: URLSessionClientProtocol) {
        self.client = client
    }
    
    // MARK: - Async
    open func fetchObject<T>(for endpoint: Endpoint) async -> FetchResult<T> where T: Decodable {
        return await fetchData(for: endpoint).flatMap { decode(data: $0) }
    }
    
    private func fetchData(for endpoint: Endpoint) async -> FetchResult<Data> {
        return await makeRequest(for: endpoint)
            .asyncFlatMap { await client.fetchData(request: $0).mapError { .urlSessionClientError($0) } }
    }
    
    // MARK: - Combine
    open func fetchObjectPublisher<T>(for endpoint: Endpoint) -> FetchPublisher<T> where T: Decodable {
        return fetchDataPublisher(for: endpoint)
            .flatMap { [weak self] data -> FetchPublisher<T> in
                guard let self = self else { return Fail(outputType: T.self, failure: .selfBeingReleased).eraseToAnyPublisher() }
                return self.decode(data: data).publisher.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchDataPublisher(for endpoint: Endpoint) -> FetchPublisher<Data> {
        return makeRequest(for: endpoint).publisher
            .flatMap { [weak self] request -> FetchPublisher<Data> in
                guard let self = self else { return Fail(outputType: Data.self, failure: .selfBeingReleased).eraseToAnyPublisher() }
                return client.fetchDataPublisher(request: request, resultAfterCancelledHandler: nil)
                    .mapError { .urlSessionClientError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

extension HTTPProvider {
    private func makeRequest(for endpoint: Endpoint) -> FetchResult<URLRequest> {
        return endpoint.makeRequest().mapError { .makeRequestError($0) }
    }
    
    private func decode<T>(data: Data) -> FetchResult<T> where T: Decodable {
        do {
            return .success(try JSONDecoder().decode(T.self, from: data))
        } catch {
            return .failure(.jsonDecodingFailure(error))
        }
    }
}

// MARK: - Fetch Error
extension HTTPProvider {
    public enum FetchError: Error {
        case urlSessionClientError(URLSessionClient.FetchError)
        case makeRequestError(HTTPEndpoint.MakeRequestError)
        case jsonDecodingFailure(Error)
        case selfBeingReleased
    }
}
