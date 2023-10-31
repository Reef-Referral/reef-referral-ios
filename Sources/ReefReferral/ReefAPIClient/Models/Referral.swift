//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 20/10/2023.
//

import Foundation

public struct Referral: Codable {
    public let referral: ReferralContent
}

public struct ReferralContent: Codable {
    public let id: String
    public let referred_status: ReferredStatus
    public let udid: String
    public let link_id: String
}
