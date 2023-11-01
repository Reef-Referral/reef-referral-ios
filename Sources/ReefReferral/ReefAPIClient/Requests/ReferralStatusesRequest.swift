//
//  ReferralStatusesRequest.swift
//
//
//  Created by Alexis Creuzot on 20/10/2023.
//

import Foundation

public struct ReferralStatusRequest: APIRequest {
    public typealias Response = ReferralStatus
    
    var link_id: String
    
    public var resourceName: String {
        return "check_referral_status"
    }
    
    public var httpMethod: HTTPMethod {
        return .post
    }
}
