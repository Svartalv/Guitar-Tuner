//
//  PitchDetectorYIN.swift
//  Guitar Tuner
//
//  Implements YIN pitch detection algorithm for monophonic fundamental frequency extraction.
//

import Foundation
import Accelerate

struct PitchDetectorYIN {
    // YIN algorithm parameters
    private let minPeriod: Int
    private let maxPeriod: Int
    private let threshold: Double = 0.1
    
    init(sampleRate: Double, minFrequency: Double = 70.0, maxFrequency: Double = 400.0) {
        // Calculate period bounds based on frequency range
        self.minPeriod = Int(sampleRate / maxFrequency)
        self.maxPeriod = Int(sampleRate / minFrequency)
    }
    
    /// Detects fundamental frequency using YIN algorithm
    /// - Parameters:
    ///   - samples: Audio samples as Float array
    ///   - sampleRate: Sample rate in Hz
    /// - Returns: Tuple of (frequencyHz, confidence) where confidence is 0.0 to 1.0
    func detect(samples: [Float], sampleRate: Double) -> (frequencyHz: Double, confidence: Double) {
        guard samples.count > maxPeriod * 2 else {
            return (0.0, 0.0)
        }
        
        let frameSize = samples.count
        let samplesDouble = samples.map { Double($0) }
        
        // Step 1: Compute difference function
        var differenceFunction = computeDifferenceFunction(samples: samplesDouble, frameSize: frameSize)
        
        // Step 2: Cumulative mean normalized difference function
        var cmndf = computeCumulativeMeanNormalizedDifference(differenceFunction: differenceFunction)
        
        // Step 3: Absolute threshold
        var period = findPeriod(cmndf: cmndf)
        
        // Step 4: Parabolic interpolation for better accuracy
        if period > 0 && period < cmndf.count - 1 {
            period = parabolicInterpolation(cmndf: cmndf, period: period)
        }
        
        // Step 5: Convert period to frequency
        guard period >= minPeriod && period <= maxPeriod else {
            return (0.0, 0.0)
        }
        
        let frequency = sampleRate / Double(period)
        
        // Compute confidence based on cmndf value at period
        let confidence = max(0.0, min(1.0, 1.0 - cmndf[period]))
        
        return (frequency, confidence)
    }
    
    private func computeDifferenceFunction(samples: [Double], frameSize: Int) -> [Double] {
        var diff = [Double](repeating: 0.0, count: maxPeriod + 1)
        
        for tau in 0...maxPeriod {
            var sum: Double = 0.0
            for j in 0..<(frameSize - maxPeriod) {
                let delta = samples[j] - samples[j + tau]
                sum += delta * delta
            }
            diff[tau] = sum
        }
        
        return diff
    }
    
    private func computeCumulativeMeanNormalizedDifference(differenceFunction: [Double]) -> [Double] {
        var cmndf = [Double](repeating: 0.0, count: differenceFunction.count)
        cmndf[0] = 1.0
        
        var runningSum: Double = 0.0
        
        for tau in 1..<differenceFunction.count {
            runningSum += differenceFunction[tau]
            if runningSum > 0 {
                cmndf[tau] = differenceFunction[tau] * Double(tau) / runningSum
            } else {
                cmndf[tau] = 1.0
            }
        }
        
        return cmndf
    }
    
    private func findPeriod(cmndf: [Double]) -> Int {
        var period = 0
        
        // Find first minimum below threshold
        for tau in minPeriod..<min(maxPeriod, cmndf.count) {
            if cmndf[tau] < threshold {
                period = tau
                break
            }
        }
        
        // If no value below threshold, find global minimum
        if period == 0 {
            var minValue = Double.greatestFiniteMagnitude
            for tau in minPeriod..<min(maxPeriod, cmndf.count) {
                if cmndf[tau] < minValue {
                    minValue = cmndf[tau]
                    period = tau
                }
            }
        }
        
        return period
    }
    
    private func parabolicInterpolation(cmndf: [Double], period: Int) -> Double {
        guard period > 0 && period < cmndf.count - 1 else {
            return Double(period)
        }
        
        let y1 = cmndf[period - 1]
        let y2 = cmndf[period]
        let y3 = cmndf[period + 1]
        
        let denominator = 2.0 * (y1 - 2.0 * y2 + y3)
        guard abs(denominator) > 1e-10 else {
            return Double(period)
        }
        
        let offset = (y1 - y3) / denominator
        return Double(period) + offset
    }
}

