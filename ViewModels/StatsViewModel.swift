//
//  StatsViewModel.swift
//  Circura
//
//  Created by Lucas Lopez
//

import Foundation

final class StatsViewModel {

    private let storage = StorageService.shared
    private let calendar = Calendar.current

    // Load all saved sessions
    private var sessions: [Session] {
        storage.loadSessions()
    }

    // MARK: - Public Computed Stats

    /// Total number of completed focus sessions.
    var totalSessions: Int {
        sessions.count
    }

    /// Total minutes focused across all sessions.
    var totalMinutesFocused: Int {
        let totalSeconds = sessions.reduce(0) { $0 + $1.duration }
        return totalSeconds / 60
    }

    /// Calculates consecutive daily streak.
    var dailyStreak: Int {
        guard !sessions.isEmpty else { return 0 }

        let uniqueDays = Set(
            sessions.map { calendar.startOfDay(for: $0.date) }
        )

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let start: Date
        if uniqueDays.contains(today) {
            start = today
        } else if uniqueDays.contains(yesterday) {
            start = yesterday
        } else {
            return 0
        }

        var streak = 0
        var current = start

        while uniqueDays.contains(current) {
            streak += 1
            current = calendar.date(byAdding: .day, value: -1, to: current)!
        }

        return streak
    }
}
