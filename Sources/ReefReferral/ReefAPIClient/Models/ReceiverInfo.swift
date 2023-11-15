//
//  Asset.swift
//  APISandbox
//
//  Created by Alexis Creuzot on 17/11/2022.
//

import Foundation

public extension Reef {
    
    struct ReceiverInfo: Codable {
        public let referred_user : Receiver
        public let offer_automatic_redirect: Bool
        public let apple_offer_url: String?
        
        public var appleOfferURL: URL? {
            guard let apple_offer_url else { return nil }
            return URL(string: apple_offer_url)
        }
    }

    struct Receiver: Codable {
        public let id: String
        public let udid: String
        public let created_at: Date
        public let referred_status: ReceiverOfferStatus
    }

}

