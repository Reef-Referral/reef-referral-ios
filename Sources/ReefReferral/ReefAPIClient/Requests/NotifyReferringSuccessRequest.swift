//
//  NotifyReferringSuccessRequest.swift
//
//
//  Created by Alexis Creuzot on 20/10/2023.
//

import Foundation

struct NotifyReferringSuccessRequest: APIRequest {
    typealias Response = ReferringInfo

    let link_id: String

    var resourceName: String {
        return "notify_referring_success"
    }

    var httpMethod: HTTPMethod {
        return .post
    }
}
