//
//  StorageService.swift
//  Circura
//
//  Created by Lucas Lopez.
//

import Foundation

/// Lightweight wrapper around UserDefaults for sessions + app settings.
final class StorageService {

    static let shared = StorageService()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Timer Length

    func getTimerLength() -> Int {
        let value = defaults.integer(forKey: "timerLength")
        return value > 0 ? value : 25
    }

    func setTimerLength(_ minutes: Int) {
        defaults.set(minutes, forKey: "timerLength")
    }

    // MARK: - Notifications Enabled

    func getNotificationsEnabled() -> Bool {
        defaults.bool(forKey: "notificationsEnabled")
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: "notificationsEnabled")
    }

    // MARK: - Sessions

    func loadSessions() -> [Session] {
        guard
            let data = defaults.data(forKey: "completedSessions"),
            let decoded = try? JSONDecoder().decode([Session].self, from: data)
        else {
            return []
        }
        return decoded
    }

    func saveSession(_ session: Session) {
        var sessions = loadSessions()
        sessions.append(session)

        if let encoded = try? JSONEncoder().encode(sessions) {
            defaults.set(encoded, forKey: "completedSessions")
        }
    }
}
