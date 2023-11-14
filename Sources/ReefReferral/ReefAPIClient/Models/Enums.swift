//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 07/11/2023.
//

import Foundation

public enum ReceiverOfferStatus: String, Codable {
    case none
    case received
    case redeemed
}

public enum SenderRewardStatus: String, Codable {
    case not_eligible
    case eligible
    case redeemed
}

public enum LogLevel {
    case debug
    case none
}

public enum ReefError : Error {
    case missingAPIKey
    
    public var localizedDescription: String {
        switch self {
        case .missingAPIKey:
            return "Missing API key, did you forget to initialize ReefReferral SDK?"
        }
    }
}
