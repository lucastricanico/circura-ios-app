//
//  TimerViewModel.swift
//  Circura
//
//  Created by Lucas Lopez
//

import Foundation
import UserNotifications
import CoreGraphics

/// ViewModel responsible for all timer logic, progress, quotes, and callbacks.
/// The ViewController only updates UI; all logic lives here.
class TimerViewModel {

    // MARK: - Outputs (closures)

    var onTimeUpdate: ((String) -> Void)?
    var onProgressUpdate: ((CGFloat) -> Void)?
    var onStateChange: ((Bool) -> Void)?
    var onQuoteUpdate: ((String) -> Void)?
    var onSessionCompleted: (() -> Void)?

    // MARK: - Internal State

    private var timer: Timer?
    private(set) var isRunning = false

    private(set) var totalSeconds: Int
    private var secondsRemaining: Int

    private var secondsSinceLastQuote = 0
    private var lastQuote: String?

    /// Formatted time string for the current remaining seconds
    var currentFormattedTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Init

    init(timerLengthMinutes: Int) {
        let length = timerLengthMinutes > 0 ? timerLengthMinutes : 25
        self.totalSeconds = length * 60
        self.secondsRemaining = self.totalSeconds
        // We don't call onTimeUpdate here because the closure
        // isn't wired up yet. The VC will pull currentFormattedTime.
    }

    // MARK: - Public Controls

    func start() {
        guard !isRunning else { return }

        isRunning = true
        onStateChange?(true)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                     repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        onStateChange?(false)
    }

    func reset() {
        pause()
        secondsRemaining = totalSeconds
        notifyTimeUpdate()
        onProgressUpdate?(0)
    }

    func updateTimerLength(to minutes: Int) {
        pause()
        totalSeconds = max(1, minutes) * 60
        secondsRemaining = totalSeconds
        notifyTimeUpdate()
        onProgressUpdate?(0)
    }

    // MARK: - Tick Handler

    private func tick() {
        guard secondsRemaining > 0 else {
            finishSession()
            return
        }

        secondsRemaining -= 1
        secondsSinceLastQuote += 1

        notifyTimeUpdate()
        notifyProgressUpdate()

        if secondsSinceLastQuote >= 60 {
            pullQuote()
            secondsSinceLastQuote = 0
        }
    }

    private func finishSession() {
        pause()

        onProgressUpdate?(1)
        onSessionCompleted?()

        let completed = Session(date: Date(), duration: totalSeconds)
        StorageService.shared.saveSession(completed)

        if UserDefaults.standard.bool(forKey: "notificationsEnabled") {
            sendCompletionNotification()
        }

        // Reset timer visually for the next run
        secondsRemaining = totalSeconds
        notifyTimeUpdate()
    }

    // MARK: - UI Binding Helpers

    private func notifyTimeUpdate() {
        onTimeUpdate?(currentFormattedTime)
    }

    private func notifyProgressUpdate() {
        let progress = CGFloat(totalSeconds - secondsRemaining) / CGFloat(totalSeconds)
        onProgressUpdate?(progress)
    }

    // MARK: - Quotes API

    func pullQuote() {
        guard let url = URL(string: "https://zenquotes.io/api/random") else { return }

        let request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 10
        )

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }

            if let error = error {
                print("Quote error: \(error)")
                if let fallback = self.lastQuote {
                    DispatchQueue.main.async { self.onQuoteUpdate?(fallback) }
                }
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                let q = json.first?["q"] as? String,
                let a = json.first?["a"] as? String
            else { return }

            let text = "“\(q)”\n— \(a)"
            self.lastQuote = text

            DispatchQueue.main.async {
                self.onQuoteUpdate?(text)
            }

        }.resume()
    }

    // MARK: - Persistence
    
    func updateNotifications(enabled: Bool) {
        StorageService.shared.setNotificationsEnabled(enabled)

        guard enabled else { return }

        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error { print("Notification error: \(error)") }
            }
    }

    // MARK: - Local notifications

    private func sendCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time's up!"
        content.body = "Your focus session has ended."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "timerCompleted",
                                        content: content,
                                        trigger: trigger)

        UNUserNotificationCenter.current().add(req)
    }
}
