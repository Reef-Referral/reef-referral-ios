//
//  API+Utils.swift
//  APISandbox
//
//  Created by Alexis Creuzot on 16/11/2022.
//

import Foundation

extension URLRequest {
    
    public var curlString: String {
        guard let url = url else { return "" }
        var baseCommand = #"curl "\#(url.absoluteString)""#
        if httpMethod == "HEAD" {
            baseCommand += " --head"
        }
        var command = [baseCommand]
        if let method = httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }
        if let headers = allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }
        if let data = httpBody, let body = String(data: data, encoding: .utf8) {
            command.append("-d '\(body)'")
        }
        return command.joined(separator: " \\\n\t")
    }
}

extension Data {
    func toJSON(_ options: JSONSerialization.WritingOptions) throws -> String {
        let json = try JSONSerialization.jsonObject(with: self, options: [.mutableContainers, .allowFragments])
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        return String(decoding: jsonData, as: UTF8.self)
    }
}

extension Dictionary {
    var queryItems: [URLQueryItem] {
        return self.map {
            URLQueryItem(name: String(describing: $0.0), value: String(describing: $0.1))
        }
    }
    
    var queryString: String {
        var components: [(String, String)] = []
        
        for key in self.keys {
            let value = self[key]!
            let tuple = (String(describing:key), String(describing: value))
            components.append(tuple)
        }
        return components.map { key, value in
            let safeKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
            return "\(safeKey)=\(value)"
        }.joined(separator: "&")
    }
    
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}

extension Encodable  {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
