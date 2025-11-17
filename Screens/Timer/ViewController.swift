//
//  ViewController.swift
//  Circura
//
//  Created by Lucas Lopez
//

import UIKit
import UserNotifications

/// Main focus-timer screen.
/// Displays a circular countdown, start/pause controls, and motivational quotes.
class ViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var circularTimerView: CircularTimerView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var startPauseButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var quoteLabel: UILabel!

    // MARK: - ViewModel

    private var viewModel: TimerViewModel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        configureNotifications()
        configureObservers()

        let savedMinutes = UserDefaults.standard.integer(forKey: "timerLength")
        let initialMinutes = savedMinutes == 0 ? 25 : savedMinutes
        viewModel = TimerViewModel(timerLengthMinutes: initialMinutes)

        bindViewModel()

        timeLabel.text = viewModel.currentFormattedTime
        circularTimerView.progress = 0

        viewModel.pullQuote()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startPauseButton.layer.cornerRadius = startPauseButton.bounds.height / 2
        startPauseButton.clipsToBounds = true
    }

    // MARK: - UI Setup

    private func configureUI() {

        view.bringSubviewToFront(timeLabel)

        resetButton.isHidden = true
        timeLabel.textColor = .white

        quoteLabel.textAlignment = .center
        quoteLabel.numberOfLines = 0
        quoteLabel.lineBreakMode = .byWordWrapping

        stylePrimaryButton()
        updateThemeColors()
        applyPlayIcon()
    }

    private func stylePrimaryButton() {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = circularTimerView.progressColor
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 18,
                                                       leading: 18,
                                                       bottom: 18,
                                                       trailing: 18)
        startPauseButton.configuration = config

        // Keep it circular
        startPauseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startPauseButton.widthAnchor.constraint(equalToConstant: 88),
            startPauseButton.heightAnchor.constraint(equalToConstant: 88)
        ])
    }

    private func updateThemeColors() {
        let accent = circularTimerView.progressColor
        quoteLabel.textColor = accent
        resetButton.tintColor = accent
        resetButton.setTitleColor(accent, for: .normal)

        startPauseButton.backgroundColor = accent
        startPauseButton.tintColor = .white
    }

    private func applyPlayIcon() {
        let config = UIImage.SymbolConfiguration(pointSize: 42, weight: .bold)
        startPauseButton.setImage(UIImage(systemName: "play.fill", withConfiguration: config),
                                  for: .normal)
    }

    private func applyPauseIcon() {
        let config = UIImage.SymbolConfiguration(pointSize: 42, weight: .bold)
        startPauseButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: config),
                                  for: .normal)
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.onTimeUpdate = { [weak self] formatted in
            self?.timeLabel.text = formatted
        }

        viewModel.onProgressUpdate = { [weak self] progress in
            self?.circularTimerView.progress = progress
        }

        viewModel.onStateChange = { [weak self] isRunning in
            guard let self else { return }
            if isRunning {
                self.applyPauseIcon()
                self.resetButton.isHidden = true
            } else {
                self.applyPlayIcon()
                self.resetButton.isHidden = false
            }
        }

        viewModel.onQuoteUpdate = { [weak self] text in
            self?.updateQuoteLabel(with: text)
        }

        viewModel.onSessionCompleted = { [weak self] in
            self?.circularTimerView.progress = 1
        }
    }

    private func updateQuoteLabel(with text: String) {
        UIView.transition(with: quoteLabel,
                          duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: {
            self.quoteLabel.text = text
        }, completion: nil)
    }

    // MARK: - Actions

    @IBAction func startPauseTapped(_ sender: UIButton) {
        if viewModel.isRunning {
            viewModel.pause()
        } else {
            viewModel.start()
        }
    }

    @IBAction func resetTapped(_ sender: UIButton) {
        viewModel.reset()
        viewModel.pullQuote()
        timeLabel.textColor = .white
    }

    // MARK: - Notifications

    private func configureNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Observer: Timer Length Changed

    private func configureObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTimerLengthChange),
            name: Notification.Name("TimerLengthDidChange"),
            object: nil
        )
    }

    @objc private func handleTimerLengthChange(_ notification: Notification) {
        guard !viewModel.isRunning else { return }

        let minutes = (notification.userInfo?["minutes"] as? Int)
            ?? UserDefaults.standard.integer(forKey: "timerLength")

        viewModel.updateTimerLength(to: minutes)

        // Reflect new initial time immediately.
        timeLabel.text = viewModel.currentFormattedTime
        circularTimerView.progress = 0
    }
}
