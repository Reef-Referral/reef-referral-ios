//
//  ColorAPIClient.swift
//  APISandbox
//
//  Created by Alexis Creuzot on 16/11/2022.
//

import Foundation

class ReefAPI : API {
    var baseEndpointUrl: URL = URL(string: "https://api.reefreferral.com/")!
    var session : URLSession = URLSession.shared
    var commonParameters : Parameters = [:]
    var commonHeaders : [String: String?] = [:]

    init(apiKey: String) {
        commonHeaders["Authorization"] = "Bearer " + apiKey
    }
}

enum ReefAPIError : LocalizedError {
    case apiError(String)
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return message
        }
    }
}

/// Specific response protocol
struct ReefAPIResponse<Response: Decodable>: Decodable {
    let error: String?
    let result: Response?
}

struct DataContainer<Result: Decodable>: Decodable {
    let result: Result?
}

class ReefAPIClient : APIClient {
    var api: API

    init(api: API) {
        self.api = api
    }

    func decode<T: APIRequest>(_ data: Data, statusCode: Int, request: T) async throws -> T.Response {
        let decodedResponse = try JSONDecoder().decode(ReefAPIResponse<T.Response>.self, from: data)
        if let message = decodedResponse.error {
            throw ReefAPIError.apiError(message)
        } else if let dataContainer = decodedResponse.result {
            return dataContainer
        } else {
            throw RequestError.decode
        }
    }

}
