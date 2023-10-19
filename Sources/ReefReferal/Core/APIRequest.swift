import Foundation

public enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case options = "OPTIONS"
    case head    = "HEAD"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum RequestError: Error {
    case decode
    case invalidURL
    case noResponse
    case unauthorized
    case unexpectedStatusCode
    case unknown
}

public protocol APIRequest: Encodable {
	associatedtype Response: Decodable
	var resourceName: String { get }
    var httpMethod: HTTPMethod { get }
}
