//
//  TuningTarget.swift
//  Guitar Tuner
//
//  Represents a tuning target with frequency constraints.
//

import Foundation

struct TuningTarget {
    let noteName: String
    let targetHz: Double
    let minHz: Double
    let maxHz: Double
    
    init(from string: TuningString) {
        self.noteName = string.noteName
        self.targetHz = string.targetFrequency
        self.minHz = string.minFrequency
        self.maxHz = string.maxFrequency
    }
    
    func isFrequencyInRange(_ frequency: Double) -> Bool {
        return frequency >= minHz && frequency <= maxHz
    }
}

