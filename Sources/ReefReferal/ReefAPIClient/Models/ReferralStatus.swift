//
//  ReferralStatus.swift
//
//
//  Created by Alexis Creuzot on 19/10/2023.
//

import Foundation

public struct ReferralStatus: Decodable {
    public enum Status: String, Codable {
        case received
        case success
    }
    
    public let referral_id: String
    public let udid: String
    public let status: Status
}
