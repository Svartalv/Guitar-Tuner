//
//  TunerEngine.swift
//  Guitar Tuner
//
//  Core tuning logic: gating, smoothing, and status computation.
//

import Foundation
import Combine

class TunerEngine: ObservableObject {
    private var selectedTarget: TuningTarget?
    private var pitchDetector: PitchDetectorYIN?
    
    // Gating thresholds
    private let rmsThreshold: Double = 0.01
    private let confidenceThreshold: Double = 0.3
    
    // Smoothing parameters
    private let smoothingAlpha: Double = 0.20
    private var smoothedCents: Double = 0.0
    private var centsHistory: [Double] = []
    private let historySize = 5
    
    // Stability tracking
    private var lastStableCents: Double = 0.0
    private var lastStableUpdateTime: Date = Date()
    private let stabilityTimeout: TimeInterval = 0.5
    
    // Publishers
    @Published var frequencyHz: Double = 0.0
    @Published var cents: Double = 0.0
    @Published var confidence: Double = 0.0
    @Published var isStable: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func setTarget(_ target: TuningTarget, sampleRate: Double) {
        selectedTarget = target
        pitchDetector = PitchDetectorYIN(
            sampleRate: sampleRate,
            minFrequency: target.minHz,
            maxFrequency: target.maxHz
        )
        reset()
    }
    
    func processAudio(samples: [Float], sampleRate: Double, rms: Double) {
        // Gate: check RMS threshold
        guard rms >= rmsThreshold else {
            updateStability(false)
            return
        }
        
        // Detect pitch
        guard let detector = pitchDetector,
              let target = selectedTarget else {
            return
        }
        
        let (detectedFreq, detectedConfidence) = detector.detect(samples: samples, sampleRate: sampleRate)
        
        // Gate: check confidence threshold
        guard detectedConfidence >= confidenceThreshold else {
            updateStability(false)
            return
        }
        
        // Gate: check frequency range
        guard target.isFrequencyInRange(detectedFreq) else {
            updateStability(false)
            return
        }
        
        // Update frequency and confidence
        frequencyHz = detectedFreq
        confidence = detectedConfidence
        
        // Compute cents deviation
        let rawCents = computeCents(frequency: detectedFreq, targetFrequency: target.targetHz)
        let clampedCents = max(-50.0, min(50.0, rawCents))
        
        // Apply median filter
        centsHistory.append(clampedCents)
        if centsHistory.count > historySize {
            centsHistory.removeFirst()
        }
        
        let medianCents = median(centsHistory)
        
        // Apply exponential smoothing
        smoothedCents = smoothingAlpha * medianCents + (1.0 - smoothingAlpha) * smoothedCents
        
        // Update published cents
        cents = smoothedCents
        
        // Update stability
        lastStableCents = smoothedCents
        lastStableUpdateTime = Date()
        updateStability(true)
    }
    
    private func computeCents(frequency: Double, targetFrequency: Double) -> Double {
        guard targetFrequency > 0 else { return 0.0 }
        return 1200.0 * log2(frequency / targetFrequency)
    }
    
    private func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        } else {
            return sorted[mid]
        }
    }
    
    private func updateStability(_ stable: Bool) {
        if stable {
            isStable = true
        } else {
            // Check if we should freeze cursor
            let timeSinceLastStable = Date().timeIntervalSince(lastStableUpdateTime)
            if timeSinceLastStable < stabilityTimeout {
                // Keep using last stable value
                isStable = true
            } else {
                isStable = false
            }
        }
    }
    
    func reset() {
        smoothedCents = 0.0
        centsHistory.removeAll()
        frequencyHz = 0.0
        confidence = 0.0
        cents = 0.0
        isStable = false
        lastStableCents = 0.0
        lastStableUpdateTime = Date()
    }
    
    func getStatus() -> (color: TuningStatusColor, message: String) {
        let absCents = abs(cents)
        
        if absCents <= 2.0 && confidence >= confidenceThreshold && isStable {
            return (.green, "You're good!")
        } else if absCents > 15.0 {
            if cents > 0 {
                return (.red, "Too sharp, tune down.")
            } else {
                return (.red, "Too flat, tune up.")
            }
        } else if absCents > 8.0 {
            if cents > 0 {
                return (.orange, "A little too sharp, tune down a bit.")
            } else {
                return (.orange, "A little too flat, tune up a bit.")
            }
        } else if absCents > 3.0 {
            if cents > 0 {
                return (.yellow, "Almost there, tune down slightly.")
            } else {
                return (.yellow, "Almost there, tune up slightly.")
            }
        } else {
            return (.yellow, "Almost there, tune up slightly.")
        }
    }
}

enum TuningStatusColor {
    case red
    case orange
    case yellow
    case green
    
    var colorValue: String {
        switch self {
        case .red: return "#FF4444"
        case .orange: return "#FF8800"
        case .yellow: return "#FFCC00"
        case .green: return "#44FF44"
        }
    }
}

