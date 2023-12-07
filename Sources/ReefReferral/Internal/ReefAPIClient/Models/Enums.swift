//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 07/11/2023.
//

import Foundation

public extension ReefReferral {
    
    enum ReceiverOfferStatus: String, Codable {
        case not_eligible = "none"
        case eligible = "eligible"
        case redeemed
    }

    enum SenderRewardStatus: String, Codable {
        case not_eligible
        case eligible
        case redeemed
    }

    enum LogLevel {
        case debug
        case none
    }

    enum ReefError : LocalizedError {
        case missingAPIKey
        case infoUnavailable

        public var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing API key, did you forget to initialize ReefReferral SDK?"
            case .infoUnavailable:
                return "Info not available."
            }
        }
    }

}
