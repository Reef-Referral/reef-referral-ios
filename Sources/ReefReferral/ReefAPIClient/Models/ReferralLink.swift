//
//  Asset.swift
//  APISandbox
//
//  Created by Alexis Creuzot on 17/11/2022.
//

import Foundation

public struct ReferralLink: Codable {
    public let link: ReferralLinkContent
}

public struct ReferralLinkContent: Codable {
    public let id: String
    public let app_id: String
    public let link_url: String
    
    public var linkURL: URL {
        return URL(string: link_url)!
    }
}
