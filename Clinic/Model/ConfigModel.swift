//
//  ConfigModel.swift
//  Clinic
//
//  Created by Admin on 25/01/23.
//

import Foundation

// MARK: - Welcome
struct ConfigModel: Codable {
    let isChatEnabled, isCallEnabled: Bool
    let workHours: String
}
