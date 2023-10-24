//
//  UserTermsAcceptedRequest.swift
//  ambassador
//
//  Created by Alexis Creuzot on 30/07/2020.
//  Copyright © 2020 waverlylabs. All rights reserved.
//

import Foundation

public struct ReferralLinkRequest: APIRequest {
    public typealias Response = ReferralLink
    
    var app_id: String
    public var resourceName: String {
        return "generate_referral_link"
    }
    
    public var httpMethod: HTTPMethod {
        return .post
    }
}
