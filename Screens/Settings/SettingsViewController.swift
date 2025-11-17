//
//  SettingsViewController.swift
//  Circura
//
//  Created by Lucas Lopez
//

import UIKit
import UserNotifications

class SettingsViewController: UIViewController {

    @IBOutlet weak var timerLengthSlider: UISlider!
    @IBOutlet weak var timerLengthLabel: UILabel!
    @IBOutlet weak var notificationsSwitch: UISwitch!

    private let viewModel = SettingsViewModel()
    private let center = UNUserNotificationCenter.current()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Sync the switch with current system authorization on appearance.
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self?.notificationsSwitch.isOn = true
                    self?.viewModel.updateNotifications(enabled: true)
                case .denied:
                    self?.notificationsSwitch.isOn = false
                    self?.viewModel.updateNotifications(enabled: false)
                case .notDetermined:
                    // Keep whatever the model says, but default to off until user opts in.
                    self?.notificationsSwitch.isOn = self?.viewModel.notificationsEnabled ?? false
                @unknown default:
                    break
                }
            }
        }
    }

    private func setupBindings() {
        viewModel.onTimerLengthChanged = { [weak self] minutes in
            self?.timerLengthLabel.text = "\(minutes) min"
        }

        viewModel.onNotificationsToggled = { [weak self] enabled in
            self?.notificationsSwitch.isOn = enabled
        }
    }

    private func configureUI() {
        timerLengthSlider.value = Float(viewModel.currentTimerLength)
        timerLengthLabel.text = "\(viewModel.currentTimerLength) min"
        notificationsSwitch.isOn = viewModel.notificationsEnabled
    }

    @IBAction func timerSliderChanged(_ sender: UISlider) {
        viewModel.updateTimerLength(to: Int(sender.value))
    }

    @IBAction func notificationsSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            center.getNotificationSettings { [weak self] settings in
                guard let self = self else { return }
                switch settings.authorizationStatus {
                case .notDetermined:
                    self.center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                        DispatchQueue.main.async {
                            self.notificationsSwitch.isOn = granted
                            self.viewModel.updateNotifications(enabled: granted)
                            if !granted {
                                // If the user declined, keep switch off.
                                self.presentNotificationsSettingsAlert()
                            }
                        }
                    }
                case .denied:
                    DispatchQueue.main.async {
                        self.notificationsSwitch.isOn = false
                        self.viewModel.updateNotifications(enabled: false)
                        self.presentNotificationsSettingsAlert()
                    }
                case .authorized, .provisional, .ephemeral:
                    DispatchQueue.main.async {
                        self.viewModel.updateNotifications(enabled: true)
                    }
                @unknown default:
                    break
                }
            }
        } else {
            // Turn off notifications: update model and remove any pending notifications.
            viewModel.updateNotifications(enabled: false)
            center.removeAllPendingNotificationRequests()
        }
    }
    
    private func presentNotificationsSettingsAlert() {
        let alert = UIAlertController(title: "Enable Notifications", message: "Notifications are turned off for this app. You can enable them in Settings.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            self?.notificationsSwitch.setOn(false, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}
