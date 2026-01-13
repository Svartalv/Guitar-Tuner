//
//  AudioInputService.swift
//  Guitar Tuner
//
//  Handles microphone input with overlapped analysis for better responsiveness.
//

import AVFoundation
import Combine

class AudioInputService: ObservableObject {
    private var engine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var sampleRate: Double = 44100.0
    
    // Overlap analysis parameters
    private let analysisWindowSize: Int = 2048
    private let hopSize: Int = 256  // Smaller hop for smoother updates (256 for best smoothness)
    private let tapBufferSize: AVAudioFrameCount = 512  // Small tap buffer for responsiveness
    
    // Ring buffer for overlapped analysis
    private var ringBuffer: [Float] = []
    private var hopAccumulator: Int = 0
    
    var audioBufferSubject = PassthroughSubject<[Float], Never>()
    var rmsLevelSubject = PassthroughSubject<Double, Never>()
    var sampleRateSubject = PassthroughSubject<Double, Never>()
    
    private var isRunning = false
    
    func start() throws {
        guard !isRunning else { return }
        
        // Request microphone permission
        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            if granted {
                DispatchQueue.main.async {
                    try? self?.setupEngine()
                }
            }
        }
        #else
        try setupEngine()
        #endif
    }
    
    private func setupEngine() throws {
        engine = AVAudioEngine()
        guard let engine = engine else { return }
        
        inputNode = engine.inputNode
        guard let inputNode = inputNode else { return }
        
        let format = inputNode.inputFormat(forBus: 0)
        sampleRate = format.sampleRate
        sampleRateSubject.send(sampleRate)
        
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [])
        try audioSession.setActive(true)
        #endif
        
        // Install tap with small buffer for responsiveness
        inputNode.installTap(onBus: 0, bufferSize: tapBufferSize, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }
        
        try engine.start()
        isRunning = true
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        
        // Compute RMS for gating
        let rms = sqrt(samples.map { Double($0) * Double($0) }.reduce(0, +) / Double(frameLength))
        rmsLevelSubject.send(rms)
        
        // Add samples to ring buffer
        ringBuffer.append(contentsOf: samples)
        
        // Keep ring buffer size manageable (keep last analysisWindowSize * 2)
        let maxBufferSize = analysisWindowSize * 2
        if ringBuffer.count > maxBufferSize {
            ringBuffer.removeFirst(ringBuffer.count - maxBufferSize)
        }
        
        // Accumulate hop
        hopAccumulator += frameLength
        
        // Process when we have enough samples and hop size reached
        if ringBuffer.count >= analysisWindowSize && hopAccumulator >= hopSize {
            // Extract analysis window (last analysisWindowSize samples)
            let startIndex = ringBuffer.count - analysisWindowSize
            let analysisSamples = Array(ringBuffer[startIndex..<ringBuffer.count])
            
            // Publish for pitch detection
            audioBufferSubject.send(analysisSamples)
            
            // Reset hop accumulator
            hopAccumulator -= hopSize
            if hopAccumulator < 0 {
                hopAccumulator = 0
            }
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        inputNode?.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        inputNode = nil
        isRunning = false
        ringBuffer.removeAll()
        hopAccumulator = 0
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
    
    func getSampleRate() -> Double {
        return sampleRate
    }
}
