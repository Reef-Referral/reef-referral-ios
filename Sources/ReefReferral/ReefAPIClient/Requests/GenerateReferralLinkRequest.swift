//
//  GenerateReferralLinkRequest.swift
//
//  Created by Alexis Creuzot on 20/10/2023.
//

import Foundation

public struct GenerateReferralLinkRequest: APIRequest {
    public typealias Response = ReferralLink
    
    var app_id: String
    var udid: String
    
    public var resourceName: String {
        return "generate_referral_link"
    }
    
    public var httpMethod: HTTPMethod {
        return .post
    }
}
