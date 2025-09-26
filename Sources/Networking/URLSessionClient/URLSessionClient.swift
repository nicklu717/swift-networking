//
//  URLSessionClient.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/6/21.
//

import Foundation
import Combine

open class URLSessionClient {
    public typealias RequestResult = Result<Data, RequestDataError>
    public typealias RequestPublisher = AnyPublisher<Data, RequestDataError>
    
    private let urlSession: URLSessionProtocol
    
    public init(urlSession: URLSessionProtocol) {
        self.urlSession = urlSession
    }
    
    open func requestData(request: URLRequest) async -> RequestResult {
        do {
            let (data, response) = try await urlSession.data(for: request)
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
            if let urlError = error as? URLError {
                return .failure(.urlSessionError(urlError))
            } else {
                return .failure(.unexpectedURLSessionError(error))
            }
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
    public enum RequestDataError: Error {
        case notHTTPResponse(URLResponse)
        case requestFailure(HTTPResponseStatus, Data)
        case urlSessionError(URLError)
        case unexpectedURLSessionError(Error)
        case selfNotExist
        case custom(String, Error?)
    }
}
