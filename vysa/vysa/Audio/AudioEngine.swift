//
//  AudioEngine.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import AVFoundation
import Foundation

/// Manages audio capture from microphone and real-time analysis pipeline
@Observable
final class AudioEngine {
    // Core audio components
    private let audioEngine: AVAudioEngine
    private let fftProcessor: FFTProcessor
    private let energyExtractor: AudioEnergyExtractor
    
    // Audio configuration
    private let bufferSize: AVAudioFrameCount = 1024
    private let sampleRate: Double = 44100.0
    
    // State
    private(set) var isRunning: Bool = false
    private(set) var currentEnergyData: AudioEnergyData = .zero
    
    // Update rate tracking
    private var lastUpdateTime: TimeInterval = 0
    private let targetUpdateRate: Double = 60.0  // 60Hz update rate
    
    // Audio buffer for FFT
    private var audioBuffer: [Float] = []
    
    /// Callback for audio energy updates (60Hz)
    var onEnergyUpdate: ((AudioEnergyData) -> Void)?
    
    init() {
        self.audioEngine = AVAudioEngine()
        self.fftProcessor = FFTProcessor()
        self.energyExtractor = AudioEnergyExtractor(fftProcessor: fftProcessor)
        
        setupAudioSession()
    }
    
    deinit {
        // Clean up - stop must not require MainActor
        if isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
    }
    
    /// Configure audio session for microphone capture
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            // Request microphone permission and configure session
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }
    
    /// Start audio capture and analysis
    func start() throws {
        guard !isRunning else { return }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // Use the input node's actual format instead of creating our own
        // This prevents format mismatch errors
        
        // Install tap on input node to capture audio
        inputNode.installTap(
            onBus: 0,
            bufferSize: bufferSize,
            format: inputFormat  // Use the actual input format
        ) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        // Start the engine
        try audioEngine.start()
        isRunning = true
        lastUpdateTime = Date().timeIntervalSince1970
        
        print("AudioEngine started successfully with format: \(inputFormat)")
    }
    
    /// Stop audio capture
    func stop() {
        guard isRunning else { return }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        
        print("AudioEngine stopped")
    }
    
    /// Process incoming audio buffer
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        
        // Copy audio data to our buffer
        let newSamples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
        audioBuffer.append(contentsOf: newSamples)
        
        // Keep buffer size manageable (2x FFT size for overlap)
        if audioBuffer.count > Int(bufferSize) * 2 {
            audioBuffer.removeFirst(audioBuffer.count - Int(bufferSize) * 2)
        }
        
        // Process at 60Hz rate
        let currentTime = Date().timeIntervalSince1970
        let deltaTime = currentTime - lastUpdateTime
        
        if deltaTime >= 1.0 / targetUpdateRate && audioBuffer.count >= Int(bufferSize) {
            performAnalysis(deltaTime: Float(deltaTime))
            lastUpdateTime = currentTime
        }
    }
    
    /// Perform FFT analysis and energy extraction
    private func performAnalysis(deltaTime: Float) {
        // Run FFT on audio buffer
        let magnitudes = fftProcessor.process(audioBuffer: audioBuffer)
        
        // Extract energy dimensions
        let energyData = energyExtractor.extract(from: magnitudes, deltaTime: deltaTime)
        
        // Update current state
        currentEnergyData = energyData
        
        // Notify listeners on main thread
        Task { @MainActor in
            self.onEnergyUpdate?(energyData)
        }
    }
    
    /// Get current audio level for UI display (0.0 to 1.0)
    var currentLevel: Float {
        currentEnergyData.intensity
    }
    
    /// Get current bass level
    var currentBass: Float {
        currentEnergyData.bassEnergy
    }
    
    /// Get current high frequency level
    var currentHigh: Float {
        currentEnergyData.highEnergy
    }
    
    /// Get current audio energy data (for particle system)
    func getCurrentEnergy() -> AudioEnergyData {
        return currentEnergyData
    }
}

// MARK: - Error Types

enum AudioEngineError: Error, LocalizedError {
    case invalidFormat
    case permissionDenied
    case engineFailure
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid audio format configuration"
        case .permissionDenied:
            return "Microphone permission denied"
        case .engineFailure:
            return "Audio engine failed to start"
        }
    }
}
