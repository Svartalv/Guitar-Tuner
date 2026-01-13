//
//  AutoStringDetector.swift
//  Guitar Tuner
//
//  Automatically detects which guitar string is being played based on frequency.
//

import Foundation

class AutoStringDetector {
    private var frequencyHistory: [Double] = []
    private var confidenceHistory: [Double] = []
    private let historySize = 8
    private var lastDetection: TuningString?
    private var detectionCount: Int = 0
    private let minDetectionCount = 3 // Require 3 consistent detections (faster response)
    
    func detectString(frequency: Double, confidence: Double) -> TuningString? {
        // Only process if we have a valid frequency and good confidence
        guard frequency > 0, confidence >= 0.25 else { // Lower confidence threshold
            return nil
        }
        
        // Add to history
        frequencyHistory.append(frequency)
        confidenceHistory.append(confidence)
        
        if frequencyHistory.count > historySize {
            frequencyHistory.removeFirst()
            confidenceHistory.removeFirst()
        }
        
        // Need enough samples
        guard frequencyHistory.count >= minDetectionCount else {
            return nil
        }
        
        // Use median frequency for stability
        let sortedFreqs = frequencyHistory.sorted()
        let medianFreq = sortedFreqs[sortedFreqs.count / 2]
        
        // Find closest matching string
        var closestString: TuningString?
        var minDistance: Double = Double.greatestFiniteMagnitude
        
        for string in TuningString.allCases {
            let target = TuningTarget(from: string)
            
            // Check if frequency is in range (wider tolerance)
            if target.isFrequencyInRange(medianFreq) {
                let distance = abs(medianFreq - target.targetHz)
                if distance < minDistance {
                    minDistance = distance
                    closestString = string
                }
            }
        }
        
        // Require frequency to be reasonably close to target (within 80 cents - more forgiving)
        if let closest = closestString {
            let target = TuningTarget(from: closest)
            let cents = 1200.0 * log2(medianFreq / target.targetHz)
            
            if abs(cents) <= 80.0 { // More forgiving
                // Count consistent detections
                if closest == lastDetection {
                    detectionCount += 1
                } else {
                    detectionCount = 1
                    lastDetection = closest
                }
                
                // Return if we have enough consistent detections
                if detectionCount >= minDetectionCount {
                    return closest
                }
            } else {
                // Reset if too far
                detectionCount = 0
                lastDetection = nil
            }
        }
        
        return nil
    }
}

