//
//  HTTPProvider.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/16.
//

import Foundation
import Combine

open class HTTPProvider<Endpoint> where Endpoint: HTTPEndpoint {
    public typealias RequestResult<T> = Result<T, RequestError>
    public typealias RequestPublisher<T> = AnyPublisher<T, RequestError>
    
    private let client: URLSessionClient
    private let jsonDecoder: JSONDecoder
    
    public init(client: URLSessionClient, jsonDecoder: JSONDecoder) {
        self.client = client
        self.jsonDecoder = jsonDecoder
    }
    
    // MARK: - Async
    open func requestData(_ endpoint: Endpoint) async -> RequestResult<Data> {
        return await endpoint.makeRequest()
            .mapError { .makeRequestError($0) }
            .asyncFlatMap {
                await client.requestData(request: $0)
                    .mapError { .urlSessionClientError($0) }
            }
    }
    
    public func requestObject<T>(_ endpoint: Endpoint) async -> RequestResult<T> where T: Decodable {
        return await requestData(endpoint).flatMap { decode(data: $0) }
    }
    
    // MARK: - Combine
    open func requestDataPublisher(_ endpoint: Endpoint) -> RequestPublisher<Data> {
        return makeRequest(endpoint).publisher
            .flatMap { [weak self] request -> RequestPublisher<Data> in
                guard let self = self else {
                    return Fail(outputType: Data.self, failure: .selfNotExist).eraseToAnyPublisher()
                }
                return client.requestDataPublisher(request: request, resultAfterCancelledHandler: nil)
                    .mapError { .urlSessionClientError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    public func requestObjectPublisher<T>(_ endpoint: Endpoint) -> RequestPublisher<T> where T: Decodable {
        return requestDataPublisher(endpoint)
            .flatMap { [weak self] data -> RequestPublisher<T> in
                guard let self = self else {
                    return Fail(outputType: T.self, failure: .selfNotExist).eraseToAnyPublisher()
                }
                return decode(data: data).publisher.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func makeRequest(_ endpoint: Endpoint) -> RequestResult<URLRequest> {
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

// MARK: - Request Error
extension HTTPProvider {
    public enum RequestError: Error {
        case urlSessionClientError(URLSessionClient.RequestDataError)
        case makeRequestError(HTTPEndpoint.MakeRequestError)
        case jsonDecodingFailure(Error)
        case selfNotExist
        case custom(String)
    }
}
