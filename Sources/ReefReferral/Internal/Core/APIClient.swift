//
//  APIClient.swift
//
//  Created by Alexis Creuzot on 26/02/2021.
//

import Foundation
import Logging

typealias Parameters = [String: Any]

protocol API {
    var baseEndpointUrl: URL {get}
    var session : URLSession {get }
    var commonParameters : Parameters {get}
    var commonHeaders: [String: String?] {get}
}

protocol APIClient {
    var api : API {get set}
    func parameters<T: APIRequest>(for request: T) -> Parameters
    func url<T: APIRequest>(for request: T) -> URL
    func send<T: APIRequest>(_ request: T) async throws -> T.Response
    func decode<T: APIRequest>(_ data: Data, statusCode: Int, request: T) async throws -> T.Response
}

extension APIClient {
    
    func parameters<T: APIRequest>(for request: T) -> Parameters {
        var params = api.commonParameters
        if let requestParams = request.dictionary {
            params.merge(dict: requestParams)
        }
        return params
    }
    
    func url<T: APIRequest>(for request: T) -> URL {
        guard   let endpointURL = URL(string: request.resourceName, relativeTo: api.baseEndpointUrl),
                var components = URLComponents(url: endpointURL,
                                           resolvingAgainstBaseURL: true) else {
                                            fatalError("Invalid resourceName: \(request.resourceName)")
        }
        
        switch request.httpMethod {
        case .get:
            components.queryItems = self.parameters(for: request).queryItems.sorted(by: { elemA, elemB in
                elemA.name > elemB.name
            })
            break
        default:
            break
        }
        return components.url!
    }
    
    /// Sends a request to servers, calling the completion method when finished
    func send<T: APIRequest>(_ request: T) async throws -> T.Response {
        let urlRequest = self.endpoint(for: request)
        let startTime = Date().timeIntervalSince1970 // Record the start time

        var debugString = "---> [\(request.httpMethod.rawValue)] \(self.api.baseEndpointUrl)\(request.resourceName)"
        
        if !self.parameters(for: request).isEmpty {
            debugString += "\n\(self.parameters(for: request) as NSDictionary)"
        }
        
        ReefReferral.logger.debug("\(debugString)")
        ReefReferral.logger.debug("\(urlRequest.curlString)")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let string = try data.toJSON([JSONSerialization.WritingOptions.prettyPrinted])

        // Calculate elapsed time after receiving the response
        let endTime = Date().timeIntervalSince1970
        let elapsedTime = endTime - startTime
        let elapsedTimeString = "\(Int(elapsedTime * 1000)) ms"
        ReefReferral.logger.debug("<--- /\(urlRequest.url!.lastPathComponent) [\(elapsedTimeString)]")
        if !string.isEmpty {
            ReefReferral.logger.debug("\(string)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.decode
        }

        return try await self.decode(data, statusCode: httpResponse.statusCode, request: request)
    }

    
    func decode<T : APIRequest>(_ data: Data, statusCode: Int, request: T) async throws -> T.Response {
        return try JSONDecoder().decode(T.Response.self, from: data)
    }
    
    /// Create URLRequest based on the given request
    func endpoint<T: APIRequest>(for request: T) -> URLRequest {
        guard let endpointURL = URL(string: request.resourceName, relativeTo: api.baseEndpointUrl),
            var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: true) else {
                fatalError("Invalid resourceName: \(request.resourceName)")
        }
        
        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for header in api.commonHeaders {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        switch request.httpMethod {
        case .get:
            components.queryItems = self.parameters(for: request).queryItems
        default:
            if let jsonData = try? JSONEncoder().encode(request) {
                urlRequest.httpBody = jsonData
            } else {
                fatalError("Failed to encode request as JSON")
            }
        }
        
        urlRequest.url = components.url
        urlRequest.httpMethod = request.httpMethod.rawValue
        return urlRequest
    }

}
