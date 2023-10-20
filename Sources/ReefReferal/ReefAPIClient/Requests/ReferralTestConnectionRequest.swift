//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 19/10/2023.
//

import Foundation

public struct ReferralTestConnectionRequest: APIRequest {
    public typealias Response = [String:Bool]
    
    var app_id: String
    public var resourceName: String {
        return "test_connection"
    }
    
    public var httpMethod: HTTPMethod {
        return .post
    }
}
