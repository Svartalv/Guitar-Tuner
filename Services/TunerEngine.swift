//
//  TunerEngine.swift
//  Guitar Tuner
//
//  Core tuning logic with soft/hard channel separation, octave correction, and reset behavior.
//

import Foundation
import Combine

enum TuningStatusBand {
    case wayOff
    case off
    case close
    case almost
    case inTune
}

class TunerEngine: ObservableObject {
    private var selectedTarget: TuningTarget?
    private var pitchDetector: PitchDetectorYIN?
    
    // RMS thresholds
    private let rmsNoSignalThreshold: Double = 0.008  // Only for "no signal" state
    private let onsetThreshold: Double = 0.015        // For transient detection
    
    // Confidence thresholds (soft vs hard)
    private let softConfidenceThreshold: Double = 0.10  // Lower for cursor responsiveness
    private let hardConfidenceThreshold: Double = 0.25  // Higher for status/lock
    
    // Lock hysteresis thresholds
    private let lockEnterCents: Double = 3.5
    private let lockExitCents: Double = 6.0
    
    // Improved dynamic smoothing alphas for cursor (tuned for feel)
    private let alphaFar: Double = 0.32
    private let alphaMid: Double = 0.24
    private let alphaNear: Double = 0.18
    
    // Cursor interpolation for smooth movement
    private var targetCents: Double = 0.0  // Updated by detection
    private var displayedCents: Double = 0.0  // Interpolated toward target
    private let followFactor: Double = 0.22  // Interpolation speed (0.18-0.28)
    private var interpolationTimer: Timer?
    
    // Soft channel (cursor) - responsive
    private var softFrequencyHz: Double = 0.0
    private var softCents: Double = 0.0
    private var softCentsSmoothed: Double = 0.0
    private var softCentsHistory: [Double] = []
    private let softHistorySize = 5
    
    // Hard channel (status/lock) - stable
    private var hardFrequencyHz: Double = 0.0
    private var hardCents: Double = 0.0
    private var hardCentsSmoothed: Double = 0.0
    
    // Transient management
    private var transientUntil: Date?
    private let transientHoldMs: TimeInterval = 0.10  // 100ms
    private var previousRms: Double = 0.0
    
    // Stability gating for hard channel
    private var stableFrameCount: Int = 0
    private var lastCandidateStatus: TuningStatusBand?
    private var currentStatusBand: TuningStatusBand = .off
    private let requiredStableFrames: Int = 6
    
    // Lock state with hysteresis
    private var isLockedState: Bool = false
    
    // Reset state management
    private var lastGoodHardTimestamp: Date = Date()
    private let resetDelayMs: TimeInterval = 0.9  // 900ms
    
    // Grace period for signal loss
    private var lastStableHardCents: Double = 0.0
    private var lastStableUpdateTime: Date = Date()
    private let signalLostGraceMs: TimeInterval = 0.8
    
    // Publishers
    @Published var frequencyHz: Double = 0.0  // Soft channel for cursor
    @Published var cents: Double = 0.0         // Soft channel smoothed cents
    @Published var confidence: Double = 0.0
    @Published var isStable: Bool = false
    @Published var isLocked: Bool = false
    @Published var statusMessage: String = "Play a string"
    @Published var statusColor: TuningStatusColor = .yellow
    @Published var cursorOpacity: Double = 0.35  // Start faded
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        startInterpolationTimer()
    }
    
    func setTarget(_ target: TuningTarget, sampleRate: Double) {
        selectedTarget = target
        // Detector uses wide range - we gate after detection
        pitchDetector = PitchDetectorYIN(
            sampleRate: sampleRate,
            minFrequency: 60.0,  // Wider than any string range
            maxFrequency: 400.0
        )
        reset()
    }
    
    private func startInterpolationTimer() {
        // Stop existing timer
        interpolationTimer?.invalidate()
        
        // Start 60fps interpolation timer on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.interpolationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
                self?.interpolateCursor()
            }
            RunLoop.current.add(self.interpolationTimer!, forMode: .common)
        }
    }
    
    private func interpolateCursor() {
        // Smooth interpolation toward target (runs on main thread)
        let diff = targetCents - displayedCents
        displayedCents += diff * followFactor
        
        // Publish interpolated value for UI
        cents = displayedCents
    }
    
    func processAudio(samples: [Float], sampleRate: Double, rms: Double) {
        let now = Date()
        
        // Always run detection - never block it
        guard let detector = pitchDetector else {
            handleSignalLoss(now: now)
            return
        }
        
        // Detect pitch (always runs)
        let detectionResult = detector.detect(samples: samples, sampleRate: sampleRate)
        var detectedFreq = detectionResult.frequencyHz
        let detectedConfidence = detectionResult.confidence
        
        // Octave correction in string mode (before computing cents)
        if let target = selectedTarget, detectedFreq > 0 {
            detectedFreq = correctOctave(frequency: detectedFreq, target: target)
        }
        
        // Update confidence (always)
        confidence = detectedConfidence
        
        // Check for signal presence (for UI state only)
        let hasSignal = rms >= rmsNoSignalThreshold
        
        // Transient detection (pluck onset)
        if previousRms < onsetThreshold && rms >= onsetThreshold {
            transientUntil = now.addingTimeInterval(transientHoldMs)
        }
        previousRms = rms
        
        let isInTransient = transientUntil != nil && now < transientUntil!
        
        // SOFT CHANNEL: Cursor movement (responsive)
        if hasSignal && detectedFreq > 0 && detectedConfidence >= softConfidenceThreshold {
            softFrequencyHz = detectedFreq
            let targetFreq = selectedTarget?.targetHz ?? 110.0
            let rawCents = computeCents(frequency: detectedFreq, targetFrequency: targetFreq)
            let clampedCents = max(-50.0, min(50.0, rawCents))
            
            // Median filter
            softCentsHistory.append(clampedCents)
            if softCentsHistory.count > softHistorySize {
                softCentsHistory.removeFirst()
            }
            let medianCents = median(softCentsHistory)
            
            // Improved dynamic alpha smoothing (tuned for feel)
            let absCents = abs(medianCents)
            let alpha: Double
            if absCents > 15.0 {
                alpha = alphaFar  // 0.32 - fast response
            } else if absCents > 6.0 {
                alpha = alphaMid  // 0.24 - balanced
            } else {
                alpha = alphaNear  // 0.18 - calm near target
            }
            
            softCentsSmoothed = alpha * medianCents + (1.0 - alpha) * softCentsSmoothed
            
            // Update target for interpolation (cursor will smoothly follow)
            targetCents = softCentsSmoothed
            
            // Publish soft channel frequency
            frequencyHz = softFrequencyHz
            isStable = true
            cursorOpacity = 1.0  // Full opacity when signal present
        } else if hasSignal && detectedFreq > 0 {
            // Low confidence but has frequency - keep moving cursor toward last target
            // Don't freeze, just fade slightly
            cursorOpacity = 0.6
            // targetCents stays at last value, interpolation continues
        } else {
            // No signal - fade cursor during grace period
            handleCursorFade(now: now)
        }
        
        // HARD CHANNEL: Status and lock (stable, gated)
        if hasSignal && detectedFreq > 0 && detectedConfidence >= hardConfidenceThreshold {
            // Check string range (only for hard channel)
            if let target = selectedTarget, target.isFrequencyInRange(detectedFreq) {
                hardFrequencyHz = detectedFreq
                let rawCents = computeCents(frequency: detectedFreq, targetFrequency: target.targetHz)
                let clampedCents = max(-50.0, min(50.0, rawCents))
                
                // Smooth hard channel (stronger smoothing)
                let alpha = 0.18
                hardCentsSmoothed = alpha * clampedCents + (1.0 - alpha) * hardCentsSmoothed
                hardCents = hardCentsSmoothed
                
                // Update timestamp for reset logic
                lastGoodHardTimestamp = now
                
                // Update lock state with hysteresis (only if not in transient)
                if !isInTransient {
                    updateLockState()
                }
                
                // Update status with stability gating (only if not in transient)
                if !isInTransient {
                    updateStatusWithGating()
                }
                
                lastStableHardCents = hardCentsSmoothed
                lastStableUpdateTime = now
            } else {
                // Frequency out of range - don't update hard channel
                // But keep last state during grace period
                let timeSinceLastStable = now.timeIntervalSince(lastStableUpdateTime)
                if timeSinceLastStable >= signalLostGraceMs && !isLockedState {
                    // Only clear if not locked and grace expired
                    checkReset(now: now)
                }
            }
        } else {
            // Low confidence or no signal - handle grace period and reset
            handleSignalLoss(now: now)
            checkReset(now: now)
        }
    }
    
    private func correctOctave(frequency: Double, target: TuningTarget) -> Double {
        var corrected = frequency
        
        // Correct octave errors (harmonics)
        while corrected < target.minHz && corrected > 0 {
            corrected *= 2.0
        }
        while corrected > target.maxHz {
            corrected /= 2.0
        }
        
        return corrected
    }
    
    private func handleCursorFade(now: Date) {
        let timeSinceLastStable = now.timeIntervalSince(lastStableUpdateTime)
        
        if timeSinceLastStable < signalLostGraceMs {
            // Grace period: fade gradually
            let fadeProgress = timeSinceLastStable / signalLostGraceMs
            cursorOpacity = 1.0 - (fadeProgress * 0.65)  // Fade to 0.35
            isStable = true
        } else {
            // After grace: keep faded
            cursorOpacity = 0.35
            isStable = false
            frequencyHz = 0.0
        }
    }
    
    private func checkReset(now: Date) {
        let timeSinceLastGood = now.timeIntervalSince(lastGoodHardTimestamp)
        
        if timeSinceLastGood >= resetDelayMs && !isLockedState {
            // Reset state
            statusMessage = "Play a string."
            statusColor = .yellow
            stableFrameCount = 0
            lastCandidateStatus = nil
            currentStatusBand = .off
        }
    }
    
    private func handleSignalLoss(now: Date) {
        let timeSinceLastStable = now.timeIntervalSince(lastStableUpdateTime)
        
        if timeSinceLastStable < signalLostGraceMs {
            // Grace period: keep showing last stable state
            // Hard channel stays frozen
        } else {
            // Grace expired: mark as unstable
            if !isLockedState {
                checkReset(now: now)
            }
        }
    }
    
    private func updateLockState() {
        let absCents = abs(hardCentsSmoothed)
        
        if isLockedState {
            // Exit lock only if significantly out of tune
            if absCents >= lockExitCents {
                isLockedState = false
            }
        } else {
            // Enter lock only when close and stable
            if absCents <= lockEnterCents {
                isLockedState = true
            }
        }
        
        isLocked = isLockedState
    }
    
    private func updateStatusWithGating() {
        // If locked, force in-tune status
        if isLockedState {
            currentStatusBand = .inTune
            statusMessage = "Perfect."
            statusColor = .green
            stableFrameCount = 0
            lastCandidateStatus = nil
            return
        }
        
        // Compute candidate status band
        let absCents = abs(hardCentsSmoothed)
        let candidateBand: TuningStatusBand
        
        if absCents > 20.0 {
            candidateBand = .wayOff
        } else if absCents > 10.0 {
            candidateBand = .off
        } else if absCents > 5.0 {
            candidateBand = .close
        } else if absCents > 3.0 {
            candidateBand = .almost
        } else {
            candidateBand = .inTune
        }
        
        // Stability gating: only commit if stable for required frames
        if candidateBand == lastCandidateStatus {
            stableFrameCount += 1
        } else {
            lastCandidateStatus = candidateBand
            stableFrameCount = 1
        }
        
        // Commit status only after stable frames
        if stableFrameCount >= requiredStableFrames {
            currentStatusBand = candidateBand
            commitStatus(band: candidateBand)
        }
    }
    
    private func commitStatus(band: TuningStatusBand) {
        switch band {
        case .wayOff:
            statusColor = .red
            if hardCentsSmoothed < 0 {
                statusMessage = "Too flat, tune up."
            } else {
                statusMessage = "Too sharp, tune down."
            }
            
        case .off:
            statusColor = .orange
            if hardCentsSmoothed < 0 {
                statusMessage = "Tune up."
            } else {
                statusMessage = "Tune down."
            }
            
        case .close:
            statusColor = .yellow
            if hardCentsSmoothed < 0 {
                statusMessage = "Close, tune up."
            } else {
                statusMessage = "Close, tune down."
            }
            
        case .almost:
            statusColor = .yellow
            if hardCentsSmoothed < 0 {
                statusMessage = "Almost, tune up slightly."
            } else {
                statusMessage = "Almost, tune down slightly."
            }
            
        case .inTune:
            statusColor = .green
            statusMessage = "Perfect."
        }
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
    
    func reset() {
        softFrequencyHz = 0.0
        softCents = 0.0
        softCentsSmoothed = 0.0
        softCentsHistory.removeAll()
        targetCents = 0.0
        displayedCents = 0.0
        hardFrequencyHz = 0.0
        hardCents = 0.0
        hardCentsSmoothed = 0.0
        frequencyHz = 0.0
        cents = 0.0
        confidence = 0.0
        isStable = false
        isLockedState = false
        isLocked = false
        lastStableHardCents = 0.0
        lastStableUpdateTime = Date()
        lastGoodHardTimestamp = Date()
        stableFrameCount = 0
        lastCandidateStatus = nil
        currentStatusBand = .off
        statusMessage = "Play a string"
        statusColor = .yellow
        transientUntil = nil
        previousRms = 0.0
        cursorOpacity = 0.35
    }
    
    deinit {
        interpolationTimer?.invalidate()
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
