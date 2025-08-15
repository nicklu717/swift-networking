//
//  HTTPEndpoint+Components.swift
//  Networking
//
//  Created by 陸瑋恩 on 2025/6/22.
//

import Foundation
import HTTPTypes

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
        
        public enum BodyType {
            case data(Data)
            case json(Encodable)
        }
    }
}
