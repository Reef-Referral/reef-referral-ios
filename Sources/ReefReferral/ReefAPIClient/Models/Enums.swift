//
//  File.swift
//  
//
//  Created by Alexis Creuzot on 07/11/2023.
//

import Foundation

public enum ReferredStatus: String, Codable {
    case none
    case received
    case success
}

public enum ReferringRewardStatus: String, Codable {
    case not_eligible
    case eligible
    case granted
}
