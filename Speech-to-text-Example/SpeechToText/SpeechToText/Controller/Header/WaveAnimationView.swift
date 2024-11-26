//
//  WaveAnimationView.swift
//
//  Created by Deepak Singh on 25/11/24.
//

import UIKit
import Combine

class WaveAnimationView: UIView {
    private var waveLayers: [CAShapeLayer] = []
    private let waveCount = 10
    private let baseWaveScale: CGFloat = 1.0
    private let maxWaveScale: CGFloat = 1.5
    private let speechManager = SpeechToTextManager.shared
    private var subscriptions = Set<AnyCancellable>()
    
    private let waveColors: [UIColor] = [
        .red, .blue, .green, .orange, .purple,
        .cyan, .magenta, .yellow, .systemPink, .systemTeal
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWaves()
        bindings()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
        setupWaves()
        bindings()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateWaveLayerFrames()
        updateWaveLayerPaths()
    }

    private func setupWaves() {
        for i in 0..<waveCount {
            let waveLayer = CAShapeLayer()
            waveLayer.fillColor = waveColors[i % waveColors.count].cgColor
            waveLayer.opacity = Float(0.4 - CGFloat(i) * 0.03) 
            layer.addSublayer(waveLayer)
            waveLayers.append(waveLayer)
        }
        updateWaveLayerFrames()
        updateWaveLayerPaths()
    }
    
    private func updateWaveLayerFrames() {
        for waveLayer in waveLayers {
            waveLayer.frame = bounds
        }
    }
    
    private func updateWaveLayerPaths() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        for (index, waveLayer) in waveLayers.enumerated() {
            let radius = bounds.width / 2 * (1 - CGFloat(index) * 0.2)
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            waveLayer.path = path.cgPath
        }
    }
    
    private func bindings() {
        speechManager.$volumeLevel
            .filter { $0 > 0.0020 }
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] volume in
                self?.updateWave(with: volume)
            }
            .store(in: &subscriptions)
    }
    
    func updateWave(with volume: Float) {
        let normalizedVolume = max(0.1, CGFloat(volume) / 0.5)
        let scale = baseWaveScale + (maxWaveScale - baseWaveScale) * normalizedVolume
        
        for (index, waveLayer) in waveLayers.enumerated() {
            let animation = CABasicAnimation(keyPath: "transform.scale")
            animation.fromValue = scale - CGFloat(index) * 0.2
            animation.toValue = scale
            animation.duration = 0.3
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            waveLayer.add(animation, forKey: "waveAnimation_\(index)")
        }
    }
    
    func resetWaves() {
        for waveLayer in waveLayers {
            waveLayer.removeAllAnimations()
        }
    }
}
