//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 20/10/2023.
//

import Foundation

public struct ReferralLinkDeleteRequest: APIRequest {
    public typealias Response = [String : Bool]
    
    var link_id: String
    public var resourceName: String {
        return "delete_referral_link"
    }
    
    public var httpMethod: HTTPMethod {
        return .post
    }
}
