//
//  BaseApi.swift
//  LazyPublish
//
//  Created by KSun on 2021/6/8.
//  Copyright © 2021 SeanGuang. All rights reserved.
//

import Foundation
import SwiftyJSON
import Firebase
import FirebaseFirestore

enum AppError: Error {
    case unknown
    case networkConnection
    case invalidToken
    case invalidJSON
    case message(reason: String)
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "common_error".localized()
        case .networkConnection:
            return "network_connection_error".localized()
        case .invalidJSON:
            return "invalid_json_error".localized()
        case .invalidToken:
            return "invalid_token_error".localized()
        case .message(let reason): return reason
        }
    }
}
