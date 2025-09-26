//
//  TestAppSettings.swift
//  swift-networking
//
//  Created by 陸瑋恩 on 2025/9/27.
//


class TestAppSettings {
    static let shared = TestAppSettings()
    
    enum TestAPIEnvironment: CaseIterable {
        case staging, production
    }
    let currentTestAPIEnvironment: TestAPIEnvironment = .staging
    
    var testAPIDomain: String {
        switch currentTestAPIEnvironment {
        case .staging:
            return "https://staging.example.com"
        case .production:
            return "https://api.example.com"
        }
    }
}