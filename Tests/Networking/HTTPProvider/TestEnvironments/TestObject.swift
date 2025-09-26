//
//  TestObject.swift
//  swift-networking
//
//  Created by 陸瑋恩 on 2025/9/27.
//

struct TestObject: Decodable, Equatable {
    let id: Int
    let name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
