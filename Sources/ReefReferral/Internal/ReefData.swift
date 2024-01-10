//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 23/10/2023.
//

import Foundation

struct ReefData: Codable, Equatable {

    static let fileURL = FileManager.default
                        .urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("reef_data.json")
    
    private var udid: String = UUID().uuidString

    var id: String { get { custom_id ?? udid }}
    var custom_id: String?
    
    var senderInfo: SenderInfo?
    var receiverInfo: ReceiverInfo?
    
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



