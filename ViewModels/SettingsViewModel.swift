//
//  SettingsViewModel.swift
//  Circura
//
//  Created by Lucas Lopez.
//

import Foundation
import UserNotifications

final class SettingsViewModel {

    private let storage = StorageService.shared

    // MARK: - Outputs (closures for VC)
    var onTimerLengthChanged: ((Int) -> Void)?
    var onNotificationsToggled: ((Bool) -> Void)?

    // MARK: - Current stored settings
    var currentTimerLength: Int {
        storage.getTimerLength()
    }

    var notificationsEnabled: Bool {
        storage.getNotificationsEnabled()
    }

    // MARK: - Update Methods

    func updateTimerLength(to minutes: Int) {
        storage.setTimerLength(minutes)
        onTimerLengthChanged?(minutes)

        NotificationCenter.default.post(
            name: Notification.Name("TimerLengthDidChange"),
            object: nil,
            userInfo: ["minutes": minutes]
        )
    }

    func updateNotifications(enabled: Bool) {
        storage.setNotificationsEnabled(enabled)
        onNotificationsToggled?(enabled)

        guard enabled else { return }

        // Ask for system permission
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error {
                    print("Notification permission error: \(error)")
                }
            }
    }
}
