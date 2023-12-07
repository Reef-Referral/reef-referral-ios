import Foundation

enum HTTPMethod: String {
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

enum RequestError: Error {
    case decode
    case invalidURL
    case noResponse
    case unauthorized
    case unexpectedStatusCode
    case unknown
}

protocol APIRequest: Encodable {
	associatedtype Response: Decodable
	var resourceName: String { get }
    var httpMethod: HTTPMethod { get }
}
