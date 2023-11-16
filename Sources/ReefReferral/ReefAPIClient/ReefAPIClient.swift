//
//  ColorAPIClient.swift
//  APISandbox
//
//  Created by Alexis Creuzot on 16/11/2022.
//

import Foundation

public class ReefAPI : API {
    //public var baseEndpointUrl: URL = URL(string: "https://api.reefreferral.com/")! //Prod
    public var baseEndpointUrl: URL = URL(string: "http://localhost:5000/")! // Dev
    public var session : URLSession = URLSession.shared
    public var commonParameters : Parameters = [:]
}

enum ReefAPIError : Error {
    case apiError(String)
    public var description: String {
        switch self {
        case .apiError(let message):
            return message
        }
    }
}

/// Specific response protocol
public struct ReefAPIResponse<Response: Decodable>: Decodable {
    public let error: String?
    public let result: Response?
}

public struct DataContainer<Result: Decodable>: Decodable {
    public let result: Result?
}

public class ReefAPIClient : APIClient {
    public static var shared = ReefAPIClient()
    public var api: API = ReefAPI()
    
    public func decode<T: APIRequest>(_ data: Data, statusCode: Int, request: T) async -> Result<T.Response, Error> {
        do {
            let decodedResponse = try JSONDecoder().decode(ReefAPIResponse<T.Response>.self, from: data)
            if let message = decodedResponse.error {
                return .failure(ReefAPIError.apiError(message))
            } else if let dataContainer = decodedResponse.result {
                return .success(dataContainer)
            } else {
                return .failure(RequestError.decode)
            }
        } catch {
            return .failure(error)
        }
    }

}
