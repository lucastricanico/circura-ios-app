//
//  CircularTimerView.swift
//  Circura
//
//  Created by Lucas Lopez
//

import UIKit

@IBDesignable
class CircularTimerView: UIView {

    // MARK: - Inspectable Properties

    @IBInspectable var progressColor: UIColor = .systemBlue {
        didSet { progressLayer.strokeColor = progressColor.cgColor }
    }

    @IBInspectable var trackColor: UIColor = UIColor.lightGray.withAlphaComponent(0.3) {
        didSet { trackLayer.strokeColor = trackColor.cgColor }
    }

    @IBInspectable var fillColor: UIColor = .clear {
        didSet { centerFillLayer.fillColor = fillColor.cgColor }
    }

    @IBInspectable var lineWidth: CGFloat = 12 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
            setNeedsLayout()
        }
    }

    @IBInspectable var progress: CGFloat = 0 {
        didSet {
            progressLayer.strokeEnd = min(max(progress, 0), 1)
        }
    }

    // MARK: - Layers

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let centerFillLayer = CAShapeLayer()

    private var currentBounds: CGRect = .zero

    
    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }


    // MARK: - Setup

    private func setupLayers() {
        backgroundColor = .clear

        // Track Layer
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        // Progress Layer
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.strokeEnd = progress
        progressLayer.lineCap = .round
        layer.addSublayer(progressLayer)

        // Center fill circle
        centerFillLayer.fillColor = fillColor.cgColor
        centerFillLayer.strokeColor = UIColor.white.withAlphaComponent(0.6).cgColor
        centerFillLayer.lineWidth = 0.5
        layer.addSublayer(centerFillLayer)
    }


    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds != currentBounds else { return }
        currentBounds = bounds

        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 3 * .pi / 2,
            clockwise: true
        )

        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath

        // Inner fill circle
        let innerRadius = radius - lineWidth * 0.5
        let innerPath = UIBezierPath(
            arcCenter: center,
            radius: innerRadius,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        centerFillLayer.path = innerPath.cgPath
    }
}
