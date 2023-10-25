//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 23/10/2023.
//

import Foundation

public struct ReefData: Codable {
    
    static let fileURL = FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("reef_data.json")
    
    var udid: String = UUID().uuidString
    public var referralId: String?
    public var referralLink: ReferralLinkContent?
    
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: ReefData.fileURL)
        } catch {
            ReefReferral.logger.error("Error saving data to file: \(error)")
        }
    }

    static func load() -> ReefData {
        do {
            let data = try Data(contentsOf: ReefData.fileURL)
            return try JSONDecoder().decode(ReefData.self, from: data)
        } catch {
            ReefReferral.logger.debug("No previous data, creating")
            return ReefData()
        }
    }
}



