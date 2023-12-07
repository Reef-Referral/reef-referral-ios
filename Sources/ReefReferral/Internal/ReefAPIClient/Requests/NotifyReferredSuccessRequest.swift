//
//  NotifyReferralSuccessRequest.swift
//
//
//  Created by Alexis Creuzot on 20/10/2023.
//

import Foundation

struct NotifyReferredSuccessRequest: APIRequest {
    typealias Response = ReceiverInfo

    let udid: String

    var resourceName: String {
        return "notify_referral_success"
    }

    var httpMethod: HTTPMethod {
        return .post
    }
}
