//
//  Asset.swift
//  APISandbox
//
//  Created by Alexis Creuzot on 17/11/2022.
//

import Foundation


public struct ReferralLink: Codable {
    let link: ReferralLinkContent
}

public struct ReferralLinkContent: Codable {
    let id: String
    let app_id: String
    let link_url: String
    
    var link: URL? {
        return URL(string: link_url)
    }
}
