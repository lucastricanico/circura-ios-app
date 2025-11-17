//
//  Session.swift
//  Circura
//
//  Created by Lucas Lopez
//

import Foundation

/// Completed focus session
/// Used for Stats (streaks, total time).
struct Session: Codable {
    let date: Date            // When the session ended
    let duration: Int         // Duration in seconds
}
