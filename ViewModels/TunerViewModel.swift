//
//  TunerViewModel.swift
//  Guitar Tuner
//
//  ViewModel coordinating audio input, pitch detection, and tuning logic.
//

import Foundation
import Combine
import SwiftUI

class TunerViewModel: ObservableObject {
    // Published properties for UI
    @Published var selectedString: TuningString = .A
    @Published var frequencyHz: Double = 0.0
    @Published var cents: Double = 0.0
    @Published var statusMessage: String = "Select a string to begin tuning."
    @Published var statusColor: Color = .gray
    @Published var cursorOpacity: Double = 0.3
    @Published var isLocked: Bool = false
    @Published var noteBadge: String = "A"
    @Published var isAutoMode: Bool = true
    @Published var detectedString: TuningString?
    
    // Services
    private let audioService = AudioInputService()
    private let tunerEngine = TunerEngine()
    private var autoDetector: AutoStringDetector?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        autoDetector = AutoStringDetector()
        setupBindings()
    }
    
    private func setupBindings() {
        // Update target when sample rate is known
        audioService.sampleRateSubject
            .sink { [weak self] sampleRate in
                guard let self = self else { return }
                let target = TuningTarget(from: self.selectedString)
                self.tunerEngine.setTarget(target, sampleRate: sampleRate)
            }
            .store(in: &cancellables)
        
        // Bind audio samples to tuner engine
        audioService.audioBufferSubject
            .combineLatest(audioService.rmsLevelSubject)
            .sink { [weak self] samples, rms in
                guard let self = self else { return }
                let sampleRate = self.audioService.getSampleRate()
                self.tunerEngine.processAudio(samples: samples, sampleRate: sampleRate, rms: rms)
            }
            .store(in: &cancellables)
        
        // Bind tuner engine outputs to published properties
        tunerEngine.$frequencyHz
            .assign(to: &$frequencyHz)
        
        tunerEngine.$cents
            .assign(to: &$cents)
        
        // Auto-detect string when frequency is detected (more responsive)
        tunerEngine.$frequencyHz
            .combineLatest(tunerEngine.$confidence, tunerEngine.$isStable)
            .sink { [weak self] frequency, confidence, stable in
                guard let self = self, self.isAutoMode, frequency > 0 else { return }
                // Don't require stable - detect even during tuning
                if let detected = self.autoDetector?.detectString(frequency: frequency, confidence: confidence) {
                    if self.detectedString != detected {
                        self.detectedString = detected
                        self.selectString(detected)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Bind cursor opacity from engine (handles fade during reset)
        tunerEngine.$cursorOpacity
            .assign(to: &$cursorOpacity)
        
        // Bind status message and color from engine (already gated for stability)
        tunerEngine.$statusMessage
            .assign(to: &$statusMessage)
        
        tunerEngine.$statusColor
            .map { statusColor in
                Color(hex: statusColor.colorValue) ?? .gray
            }
            .assign(to: &$statusColor)
        
        // Bind locked state from engine (with hysteresis)
        tunerEngine.$isLocked
            .assign(to: &$isLocked)
    }
    
    func selectString(_ string: TuningString) {
        selectedString = string
        noteBadge = string.displayName  // Use displayName (E, A, D, G, B, E) - letters only
        
        let target = TuningTarget(from: string)
        let sampleRate = audioService.getSampleRate()
        tunerEngine.setTarget(target, sampleRate: sampleRate)
    }
    
    func toggleAutoMode() {
        isAutoMode.toggle()
        if !isAutoMode {
            detectedString = nil
        }
    }
    
    func startTuning() {
        do {
            try audioService.start()
        } catch {
            print("Failed to start audio: \(error)")
        }
    }
    
    func stopTuning() {
        audioService.stop()
        tunerEngine.reset()
    }
    
    deinit {
        stopTuning()
    }
}

// Color extension for hex support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

