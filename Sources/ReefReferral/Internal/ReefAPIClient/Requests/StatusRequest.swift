//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 06/11/2023.
//

import Foundation

struct StatusResponse: Codable {
    let sender: SenderInfo
    let receiver: ReceiverInfo?
}
struct StatusRequest: APIRequest {
    typealias Response = StatusResponse

    var udid: String
    var custom_id: String?
    let receipt_data: String
    
    var resourceName: String {
        return "status"
    }
    
    var httpMethod: HTTPMethod {
        return .post
    }
}
