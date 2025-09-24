//
//  HTTPProvider.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/7/16.
//

import Foundation
import Combine
import Utilities

open class HTTPProvider<Endpoint> where Endpoint: HTTPEndpoint {
    public typealias RequestObjectResult<T> = Result<T, RequestObjectError>
    public typealias RequestObjectPublisher<T> = AnyPublisher<T, RequestObjectError>
    
    private let client: URLSessionClient
    private let jsonDecoder: JSONDecoder
    
    public init(client: URLSessionClient, jsonDecoder: JSONDecoder) {
        self.client = client
        self.jsonDecoder = jsonDecoder
    }
    
    // MARK: - Async
    open func requestObject<T>(_ endpoint: Endpoint) async -> RequestObjectResult<T> where T: Decodable {
        return await requestData(endpoint).flatMap { decode(data: $0) }
    }
    
    open func requestData(_ endpoint: Endpoint) async -> RequestObjectResult<Data> {
        return await makeRequest(for: endpoint)
            .asyncFlatMap {
                await client.requestData(request: $0)
                    .mapError { .urlSessionClientError($0) }
            }
    }
    
    // MARK: - Combine
    open func requestObjectPublisher<T>(_ endpoint: Endpoint) -> RequestObjectPublisher<T> where T: Decodable {
        return requestDataPublisher(endpoint)
            .flatMap { [weak self] data -> RequestObjectPublisher<T> in
                guard let self = self else {
                    return Fail(outputType: T.self, failure: .selfNotExist).eraseToAnyPublisher()
                }
                return decode(data: data).publisher.eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    open func requestDataPublisher(_ endpoint: Endpoint) -> RequestObjectPublisher<Data> {
        return makeRequest(for: endpoint).publisher
            .flatMap { [weak self] request -> RequestObjectPublisher<Data> in
                guard let self = self else {
                    return Fail(outputType: Data.self, failure: .selfNotExist).eraseToAnyPublisher()
                }
                return client.requestDataPublisher(request: request, resultAfterCancelledHandler: nil)
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

// MARK: - Error
extension HTTPProvider {
    
    public enum RequestObjectError: Error {
        case urlSessionClientError(URLSessionClient.RequestDataError)
        case makeRequestError(HTTPEndpoint.MakeRequestError)
        case jsonDecodingFailure(Error)
        case selfNotExist
        case custom(String)
    }
}
