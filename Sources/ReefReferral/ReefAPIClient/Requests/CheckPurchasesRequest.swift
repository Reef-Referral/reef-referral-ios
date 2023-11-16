//
//  CheckPurchasesRequest.swift
//
//
//  Created by Alexis Creuzot on 16/11/2023.
//

import Foundation

public extension Reef {
    struct CheckPurchasesResponse : Codable {
        let verification_result: String
        let purchased: String
        let used_promo_code: String
    }
}

struct CheckPurchasesRequest: APIRequest {
    typealias Response = Reef.CheckPurchasesResponse

    let link_id: String
    let receipt_data: String

    var resourceName: String {
        return "check_purchases"
    }

    var httpMethod: HTTPMethod {
        return .post
    }
}
