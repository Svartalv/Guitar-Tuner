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
    
    // Services
    private let audioService = AudioInputService()
    private let tunerEngine = TunerEngine()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
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
        
        tunerEngine.$isStable
            .map { [weak self] stable in
                guard let self = self else { return 0.3 }
                return stable ? 1.0 : 0.3
            }
            .assign(to: &$cursorOpacity)
        
        // Update status based on tuning state
        tunerEngine.$cents
            .combineLatest(tunerEngine.$isStable, tunerEngine.$confidence)
            .map { [weak self] _, _, _ in
                guard let self = self else { return (.gray, "Select a string to begin tuning.") }
                let status = self.tunerEngine.getStatus()
                let color = Color(hex: status.color.colorValue) ?? .gray
                return (color, status.message)
            }
            .sink { [weak self] color, message in
                self?.statusColor = color
                self?.statusMessage = message
            }
            .store(in: &cancellables)
        
        // Update locked state
        tunerEngine.$cents
            .combineLatest(tunerEngine.$isStable, tunerEngine.$confidence)
            .map { cents, stable, confidence in
                abs(cents) <= 2.0 && stable && confidence >= 0.3
            }
            .assign(to: &$isLocked)
    }
    
    func selectString(_ string: TuningString) {
        selectedString = string
        noteBadge = string.displayName
        
        let target = TuningTarget(from: string)
        let sampleRate = audioService.getSampleRate()
        tunerEngine.setTarget(target, sampleRate: sampleRate)
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

