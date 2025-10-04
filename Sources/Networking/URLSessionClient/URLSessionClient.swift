//
//  URLSessionClient.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/6/21.
//

import Foundation
import Combine

open class URLSessionClient {
    public typealias RequestResult = Result<Data, RequestError>
    public typealias RequestPublisher = AnyPublisher<Data, RequestError>
    
    private let urlSession: URLSessionProtocol
    private let plugins: [Plugin]
    
    public init(urlSession: URLSessionProtocol, plugins: [Plugin] = []) {
        self.urlSession = urlSession
        self.plugins = plugins
    }
    
    open func requestData(request: URLRequest) async -> RequestResult {
        do {
            let request = plugins.reduce(request) { $1.modify(request: $0) }
            plugins.forEach { $0.willSend(request: request) }
            
            let (data, response) = try await urlSession.data(for: request)
            plugins.forEach { $0.didReceive(data: data, response: response, request: request) }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.notHTTPResponse(response))
            }
            let status = HTTPResponseStatus(integerLiteral: httpResponse.statusCode)
            if status.kind == .successful {
                return .success(data)
            } else {
                return .failure(.requestFailure(status, data))
            }
        } catch {
            return .failure(.urlSessionError((error as? URLError) ?? URLError(.unknown)))
        }
    }
    
    open func requestDataPublisher(
        request: URLRequest,
        resultAfterCancelledHandler: ((RequestResult) -> Void)? = nil
    ) -> RequestPublisher {
        var underlyingTask: Task<Void, Never>?
        return Deferred { [weak self] in
            Future { promise in
                underlyingTask = Task {
                    let result: RequestResult = await {
                        guard let self = self else { return .failure(.selfNotExist) }
                        return await self.requestData(request: request)
                    }()
                    if Task.isCancelled {
                        resultAfterCancelledHandler?(result)
                    } else {
                        promise(result)
                    }
                }
            }
        }
        .handleEvents(
            receiveCancel: {
                underlyingTask?.cancel()
            }
        )
        .eraseToAnyPublisher()
    }
    
    public func requestData(url: URL) async -> RequestResult {
        return await requestData(request: URLRequest(url: url))
    }
    
    public func requestDataPublisher(
        url: URL,
        resultAfterCancelledHandler: ((RequestResult) -> Void)?
    ) -> RequestPublisher {
        return requestDataPublisher(request: URLRequest(url: url), resultAfterCancelledHandler: resultAfterCancelledHandler)
    }
}

// MARK: - Request Error
extension URLSessionClient {
    public enum RequestError: Error {
        case notHTTPResponse(URLResponse)
        case requestFailure(HTTPResponseStatus, Data)
        case urlSessionError(URLError)
        case selfNotExist
        case custom(String)
    }
}
