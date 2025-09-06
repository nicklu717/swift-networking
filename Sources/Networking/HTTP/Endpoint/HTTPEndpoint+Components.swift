//
//  HTTPEndpoint+Components.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/6/22.
//

import Foundation
import HTTPTypes
import Utilities

extension HTTPEndpoint {
    
    public struct HTTPHeader {
        let field: HTTPField.Name
        let value: String
        
        public init(_ field: HTTPField.Name, _ value: String) {
            self.field = field
            self.value = value
        }
        
        public init(_ customField: String, _ value: String) {
            self.init(HTTPField.Name(customField)!, value)
        }
    }
    
    public typealias HTTPMethod = HTTPRequest.Method
    
    public enum HTTPParameter {
        case url(queries: [String: String])
        case body(BodyType)
        case dictionary([String: Any])
        
        public enum BodyType {
            case data(Data)
            case json(Encodable)
        }
    }
}

// MARK: - Common Header Values
public extension HTTPEndpoint.HTTPHeader {
    
    static func authorization(_ authorization: Authorization) -> Self {
        Self(.authorization, authorization.value)
    }
    enum Authorization {
        case raw(String)
        case basic(username: String, password: String)
        case bearer(token: String)
        
        var value: String {
            switch self {
            case .raw(let value):
                return value
            case .basic(let username, let password):
                return "Basic \(Data("\(username):\(password)".utf8).base64EncodedString())"
            case .bearer(let token):
                return "Bearer \(token)"
            }
        }
    }
    
    static func accept(_ contentType: ContentType) -> Self {
        Self(.accept, contentType.rawValue)
    }
    static func contentType(_ contentType: ContentType) -> Self {
        Self(.contentType, contentType.rawValue)
    }
    enum ContentType: String {
        case json = "application/json"
        case formURLEncoded = "application/x-www-form-urlencoded"
        case multipartFormData = "multipart/form-data"
        case plain = "text/plain"
        case html = "text/html"
    }
}
