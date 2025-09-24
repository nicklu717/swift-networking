//
//  URLError+Status.swift
//  swift-networking
//
//  Created by 陸瑋恩 on 2025/9/24.
//

import Foundation

extension URLError {
    var isCancelled: Bool { code == .cancelled }
    var isTimedOut: Bool { code == .timedOut }
}
