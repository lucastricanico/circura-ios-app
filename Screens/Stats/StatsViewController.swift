//
//  StatsViewController.swift
//  Circura
//
//  Created by Lucas Lopez
//

import UIKit
import UserNotifications

final class StatsViewController: UIViewController {

    @IBOutlet weak var totalSessionsLabel: UILabel!
    @IBOutlet weak var totalFocusedTimeLabel: UILabel!
    @IBOutlet weak var dailyStreakLabel: UILabel!
    @IBOutlet weak var notificationsSwitch: UISwitch!

    private let viewModel = StatsViewModel()
    private let notificationsEnabledKey = "notificationsEnabled"

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStats()
        notificationsSwitch?.isOn = UserDefaults.standard.bool(forKey: notificationsEnabledKey)
    }

    private func updateStats() {
        totalSessionsLabel.text = "Total Sessions: \(viewModel.totalSessions)"
        totalFocusedTimeLabel.text = "Total Focused Time: \(viewModel.totalMinutesFocused) minutes"
        dailyStreakLabel.text = "Daily Streak: \(viewModel.dailyStreak) days"
    }

    @IBAction func notificationsSwitchToggled(_ sender: UISwitch) {
        if sender.isOn {
            requestNotificationAuthorization()
        } else {
            // Turning off notifications in-app; persist preference.
            UserDefaults.standard.set(false, forKey: notificationsEnabledKey)
        }
    }

    private func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        self?.notificationsSwitch?.isOn = granted
                        UserDefaults.standard.set(granted, forKey: self?.notificationsEnabledKey ?? "notificationsEnabled")
                    }
                }
            case .denied:
                // Guide the user to Settings to enable notifications if previously denied.
                DispatchQueue.main.async {
                    self?.notificationsSwitch?.isOn = false
                    UserDefaults.standard.set(false, forKey: self?.notificationsEnabledKey ?? "notificationsEnabled")
                    self?.presentNotificationsSettingsAlert()
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    self?.notificationsSwitch?.isOn = true
                    UserDefaults.standard.set(true, forKey: self?.notificationsEnabledKey ?? "notificationsEnabled")
                }
            @unknown default:
                break
            }
        }
    }

    private func presentNotificationsSettingsAlert() {
        let alert = UIAlertController(title: "Enable Notifications", message: "Notifications are turned off for this app. You can enable them in Settings.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            self?.notificationsSwitch?.setOn(false, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}
