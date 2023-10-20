//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 20/10/2023.
//

import Foundation

public struct Referral: Codable {
    let referral: ReferralContent
}

public struct ReferralContent: Codable {
    let id: String
    let status: ReferralStatus.Status
    let udid: String
    let link_id: String
}
