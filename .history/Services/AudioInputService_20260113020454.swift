//
//  AudioInputService.swift
//  Guitar Tuner
//
//  Handles microphone input using AVAudioEngine.
//

import AVFoundation
import Combine

class AudioInputService: ObservableObject {
    private var engine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var sampleRate: Double = 44100.0
    private let bufferSize: AVAudioFrameCount = 2048
    
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
        
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [])
        try audioSession.setActive(true)
        #endif
        
        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
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
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Double(frameLength))
        rmsLevelSubject.send(rms)
        
        // Publish samples for pitch detection
        audioBufferSubject.send(samples)
    }
    
    func stop() {
        guard isRunning else { return }
        
        inputNode?.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        inputNode = nil
        isRunning = false
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
    
    func getSampleRate() -> Double {
        return sampleRate
    }
}

