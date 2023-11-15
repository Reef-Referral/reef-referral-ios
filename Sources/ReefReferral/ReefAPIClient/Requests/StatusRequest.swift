//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 06/11/2023.
//

import Foundation

public struct StatusRequest: APIRequest {
    public typealias Response = Reef.SenderInfo
    
    var udid: String
    var app_id: String
    
    public var resourceName: String {
        return "status"
    }
    
    public var httpMethod: HTTPMethod {
        return .post
    }
}
