//
//  HandleDeepLinkRequest.swift
//
//
//  Created by Alexis Creuzot on 20/10/2023.
//

import Foundation

struct HandleDeepLinkRequest: APIRequest {
    typealias Response = Reef.ReceiverInfo

    let link_id: String
    let udid: String

    var resourceName: String {
        return "handle_deep_link"
    }

    var httpMethod: HTTPMethod {
        return .post
    }
}
