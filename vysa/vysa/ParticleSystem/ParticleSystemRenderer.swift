//
//  ParticleSystemRenderer.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import Metal
import MetalKit
import RealityKit
import simd

/// Main particle system that manages Metal rendering and audio integration
@MainActor
class ParticleSystemRenderer {
    
    // MARK: - Properties
    
    private var metalDevice: MTLDevice?
    private var computePipelineState: MTLComputePipelineState?
    private var commandQueue: MTLCommandQueue?
    
    private var particleBuffer: MTLBuffer?
    private var uniformsBuffer: MTLBuffer?
    
    private var particles: [ParticleData] = []
    private let particleCount: Int
    private let scale: Float
    
    private var audioEngine: AudioEngine?
    private var modeManager: ModeManager
    
    private var startTime: Date = Date()
    private var lastUpdateTime: Date = Date()
    
    // Test mode - generates synthetic audio for visualization
    private var testMode: Bool = false  // Set to false to use real microphone
    
    // MARK: - Initialization
    
    init(particleCount: Int = 10_000, scale: Float = 1.0) {  // Reduced for simulator performance
        self.particleCount = particleCount
        self.scale = scale
        self.modeManager = ModeManager()
        
        setupMetal()
        initializeParticles()
        setupAudio()
    }
    
    // MARK: - Setup
    
    private func setupMetal() {
        // Get Metal device
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ Metal not supported on this device")
            return
        }
        self.metalDevice = device
        
        // Create command queue
        self.commandQueue = device.makeCommandQueue()
        
        // Load Metal shader library
        guard let library = device.makeDefaultLibrary() else {
            print("❌ Failed to create Metal library")
            return
        }
        
        // Get compute function
        guard let computeFunction = library.makeFunction(name: "updateParticles") else {
            print("❌ Failed to find updateParticles function")
            return
        }
        
        // Create compute pipeline
        do {
            self.computePipelineState = try device.makeComputePipelineState(function: computeFunction)
            print("✅ Metal compute pipeline created successfully")
        } catch {
            print("❌ Failed to create compute pipeline: \(error)")
        }
    }
    
    private func initializeParticles() {
        guard let device = metalDevice else { return }
        
        // Generate initial positions using current mode
        let basePositions = modeManager.currentMode.generateBasePositions(
            particleCount: particleCount,
            scale: scale
        )
        
        // Create particle data
        particles = basePositions.enumerated().map { index, position in
            let frequencyBand = Float(index) / Float(particleCount)
            return ParticleData(basePosition: position, frequencyBand: frequencyBand)
        }
        
        // Create Metal buffer
        let bufferSize = MemoryLayout<ParticleData>.stride * particles.count
        particleBuffer = device.makeBuffer(
            bytes: particles,
            length: bufferSize,
            options: .storageModeShared
        )
        
        // Create uniforms buffer
        let uniformsSize = MemoryLayout<ParticleUniformsData>.stride
        uniformsBuffer = device.makeBuffer(
            length: uniformsSize,
            options: .storageModeShared
        )
        
        print("✅ Initialized \(particles.count) particles")
    }
    
    private func setupAudio() {
        audioEngine = AudioEngine()
        do {
            try audioEngine?.start()
            print("✅ Audio engine started")
        } catch {
            print("⚠️ Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Update
    
    func update() {
        let currentTime = Date()
        let deltaTime = Float(currentTime.timeIntervalSince(lastUpdateTime))
        let totalTime = Float(currentTime.timeIntervalSince(startTime))
        lastUpdateTime = currentTime
        
        // Get audio data (use synthetic test mode or real audio)
        let audioData: AudioEnergyData
        if testMode {
            audioData = generateSyntheticAudio(time: totalTime)
        } else {
            audioData = audioEngine?.getCurrentEnergy() ?? AudioEnergyData.zero
        }
        
        // CPU-based particle update (temporary workaround for Metal struct alignment)
        updateParticlesCPU(deltaTime: deltaTime, time: totalTime, audioData: audioData)
    }
    
    /// Generate synthetic audio data for testing without microphone
    private func generateSyntheticAudio(time: Float) -> AudioEnergyData {
        // Simulate a beat at ~120 BPM
        let bpm: Float = 120.0
        let beatInterval: Float = 60.0 / bpm
        let beatPhase = (time / beatInterval).truncatingRemainder(dividingBy: 1.0)
        
        // Bass pulse on beat
        let bassEnergy = max(0, 1.0 - beatPhase * 4.0) // Sharp attack, quick decay
        
        // Mid energy with slower modulation
        let midEnergy = 0.3 + 0.3 * sin(time * 2.0)
        
        // High energy with faster modulation
        let highEnergy = 0.4 + 0.3 * sin(time * 8.0)
        
        // Overall intensity
        let intensity = 0.5 + 0.3 * bassEnergy + 0.2 * sin(time * 1.5)
        
        // Punch is high on beats
        let punch = bassEnergy * 0.8
        
        // Generate frequency bands with varying energies
        var bands: [Float] = []
        for i in 0..<64 {
            let freq = Float(i) / 64.0
            // Low frequencies follow bass, mid follow mids, high follow highs
            let energy: Float
            if freq < 0.2 {
                energy = bassEnergy * (0.5 + 0.5 * sin(time * 3.0 + Float(i)))
            } else if freq < 0.6 {
                energy = midEnergy * (0.5 + 0.5 * cos(time * 4.0 + Float(i)))
            } else {
                energy = highEnergy * (0.5 + 0.5 * sin(time * 6.0 + Float(i)))
            }
            bands.append(energy)
        }
        
        return AudioEnergyData(
            intensity: intensity,
            bassEnergy: bassEnergy,
            highEnergy: highEnergy,
            punch: punch,
            frequencyBands: bands,
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    private func updateParticlesCPU(deltaTime: Float, time: Float, audioData: AudioEnergyData) {
        guard let buffer = particleBuffer else { return }
        
        let pointer = buffer.contents().bindMemory(
            to: ParticleData.self,
            capacity: particleCount
        )
        
        // Update each particle on CPU
        for i in 0..<particleCount {
            var particle = pointer[i]
            
            // Get frequency band for this particle
            let bandIndex = Int(particle.frequencyBand * 63.0)
            let bandEnergy = bandIndex < audioData.frequencyBands.count ? audioData.frequencyBands[bandIndex] : 0
            
            // Simple audio-reactive animation
            let audioDisplacement = normalize(particle.basePosition) * audioData.intensity * 0.2
            let targetPosition = particle.basePosition + audioDisplacement
            
            // Spring physics toward target - with damping to prevent drift
            let toTarget = targetPosition - particle.position
            particle.velocity = particle.velocity * 0.9 + toTarget * 3.0 * deltaTime
            particle.position = particle.position + particle.velocity * deltaTime
            
            // Clamp position to prevent particles from drifting too far
            let maxDistance: Float = 2.0
            let distanceFromBase = length(particle.position - particle.basePosition)
            if distanceFromBase > maxDistance {
                let direction = normalize(particle.position - particle.basePosition)
                particle.position = particle.basePosition + direction * maxDistance
                particle.velocity = particle.velocity * 0.5  // Dampen velocity at bounds
            }
            
            // Update color based on audio
            var color = SIMD4<Float>(0.2, 0.3, 0.8, 1.0)
            color.x += audioData.bassEnergy * 0.6  // Red increases with bass
            color.y += audioData.highEnergy * 0.5   // Green increases with highs
            color.z += audioData.bassEnergy * 0.2   // Blue (z component, not b)
            let brightness = 0.5 + audioData.intensity * 0.5
            color = color * brightness
            particle.color = simd_clamp(color, SIMD4<Float>(0,0,0,0), SIMD4<Float>(1,1,1,1))
            
            // Update size
            particle.size = 0.01 * scale * (1.0 + bandEnergy * 0.5)
            
            pointer[i] = particle
        }
    }
    
    private func runComputeShader() {
        guard let device = metalDevice,
              let commandQueue = commandQueue,
              let computePipeline = computePipelineState,
              let particleBuffer = particleBuffer,
              let uniformsBuffer = uniformsBuffer else {
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(particleBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(uniformsBuffer, offset: 0, index: 1)
        
        // Calculate thread groups
        let threadGroupSize = MTLSize(
            width: min(computePipeline.threadExecutionWidth, particleCount),
            height: 1,
            depth: 1
        )
        let threadGroups = MTLSize(
            width: (particleCount + threadGroupSize.width - 1) / threadGroupSize.width,
            height: 1,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
    }
    
    // MARK: - Access
    
    func getParticles() -> [ParticleData] {
        guard let buffer = particleBuffer else { return [] }
        
        let pointer = buffer.contents().bindMemory(
            to: ParticleData.self,
            capacity: particleCount
        )
        return Array(UnsafeBufferPointer(start: pointer, count: particleCount))
    }
    
    // MARK: - Mode Control
    
    func nextMode() {
        modeManager.nextMode()
        print("✅ Switched to mode: \(modeManager.currentMode.name)")
    }
    
    func previousMode() {
        modeManager.previousMode()
        print("✅ Switched to mode: \(modeManager.currentMode.name)")
    }
    
    var currentModeName: String {
        modeManager.currentMode.name
    }
    
    // MARK: - Cleanup
    
    func stop() {
        audioEngine?.stop()
    }
}
