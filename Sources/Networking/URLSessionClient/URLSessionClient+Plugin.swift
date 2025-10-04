//
//  URLSessionClient.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/6/21.
//

import Foundation
import Combine

extension URLSessionClient {
    
    open class Plugin {
        open func modify(request: URLRequest) -> URLRequest { return request }
        open func willSend(request: URLRequest) {}
        open func didReceive(data: Data, response: URLResponse, request: URLRequest) {}
    }
}
