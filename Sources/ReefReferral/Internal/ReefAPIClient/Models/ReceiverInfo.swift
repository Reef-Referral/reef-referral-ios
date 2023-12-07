//
//  Asset.swift
//  APISandbox
//
//  Created by Alexis Creuzot on 17/11/2022.
//

import Foundation

struct ReceiverInfo: Codable {
    let referred_user : Receiver
    let offer_automatic_redirect: Bool
    let apple_offer_url: String?

    var appleOfferURL: URL? {
        guard let apple_offer_url else { return nil }
        return URL(string: apple_offer_url)
    }
}

struct Receiver: Codable {
    let id: String
    let udid: String
    let created_at: Date
    let referred_status: ReefReferral.ReceiverOfferStatus
}
