//
//  AudioEnergyExtractor.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Accelerate
import Foundation

/// Extracts four energy dimensions from FFT magnitude data with temporal smoothing
final class AudioEnergyExtractor {
    private let fftProcessor: FFTProcessor
    private let bandCount: Int = 64  // Number of logarithmic frequency bands
    
    // Temporal smoothing parameters
    private let attackTime: Float = 0.05   // 50ms attack (fast response)
    private let decayTime: Float = 0.15    // 150ms decay (smooth falloff)
    
    // Previous values for smoothing
    private var previousIntensity: Float = 0.0
    private var previousBassEnergy: Float = 0.0
    private var previousHighEnergy: Float = 0.0
    private var previousPunch: Float = 0.0
    private var previousBands: [Float]
    
    // For punch detection
    private var previousAmplitude: Float = 0.0
    
    // Noise gate threshold
    private let noiseGateThreshold: Float = 0.01
    
    init(fftProcessor: FFTProcessor) {
        self.fftProcessor = fftProcessor
        self.previousBands = Array(repeating: 0.0, count: bandCount)
    }
    
    /// Extract energy dimensions from FFT magnitudes
    /// - Parameters:
    ///   - magnitudes: FFT magnitude array from FFTProcessor
    ///   - deltaTime: Time since last update in seconds
    /// - Returns: AudioEnergyData with four energy dimensions and frequency bands
    func extract(from magnitudes: [Float], deltaTime: Float) -> AudioEnergyData {
        // Calculate RMS for overall intensity (full spectrum)
        let intensity = calculateRMS(magnitudes: magnitudes)
        
        // Apply noise gate
        guard intensity > noiseGateThreshold else {
            return applySmoothing(
                to: AudioEnergyData.zero,
                deltaTime: deltaTime
            )
        }
        
        // Extract bass energy (20-250 Hz)
        let bassEnergy = fftProcessor.getMagnitudeInRange(
            magnitudes: magnitudes,
            minFreq: 20.0,
            maxFreq: 250.0
        )
        
        // Extract high frequency energy (4-16 kHz)
        let highEnergy = fftProcessor.getMagnitudeInRange(
            magnitudes: magnitudes,
            minFreq: 4000.0,
            maxFreq: 16000.0
        )
        
        // Calculate punch (transient detection via amplitude delta)
        let punch = max(0.0, intensity - previousAmplitude)
        previousAmplitude = intensity
        
        // Extract 64 logarithmic frequency bands
        let frequencyBands = extractLogarithmicBands(from: magnitudes)
        
        // Create raw energy data
        let rawData = AudioEnergyData(
            intensity: clamp(intensity * 2.0, min: 0.0, max: 1.0),  // Scale up for better response
            bassEnergy: clamp(bassEnergy * 3.0, min: 0.0, max: 1.0),  // Bass boost
            highEnergy: clamp(highEnergy * 2.5, min: 0.0, max: 1.0),
            punch: clamp(punch * 5.0, min: 0.0, max: 1.0),  // Emphasize transients
            frequencyBands: frequencyBands.map { clamp($0, min: 0.0, max: 1.0) },
            timestamp: Date().timeIntervalSince1970
        )
        
        // Apply temporal smoothing
        return applySmoothing(to: rawData, deltaTime: deltaTime)
    }
    
    /// Calculate RMS (Root Mean Square) of magnitudes
    private func calculateRMS(magnitudes: [Float]) -> Float {
        var sumOfSquares: Float = 0.0
        vDSP_svesq(magnitudes, 1, &sumOfSquares, vDSP_Length(magnitudes.count))
        return sqrt(sumOfSquares / Float(magnitudes.count))
    }
    
    /// Extract logarithmic frequency bands for musical representation
    private func extractLogarithmicBands(from magnitudes: [Float]) -> [Float] {
        var bands = [Float](repeating: 0.0, count: bandCount)
        
        // Logarithmic spacing from 20 Hz to 20 kHz
        let minFreq = 20.0
        let maxFreq = 20000.0
        let freqRatio = pow(maxFreq / minFreq, 1.0 / Double(bandCount))
        
        for i in 0..<bandCount {
            let centerFreq = minFreq * pow(freqRatio, Double(i))
            let bandwidth = centerFreq * (freqRatio - 1.0)
            
            let minBandFreq = centerFreq - bandwidth / 2.0
            let maxBandFreq = centerFreq + bandwidth / 2.0
            
            let energy = fftProcessor.getMagnitudeInRange(
                magnitudes: magnitudes,
                minFreq: minBandFreq,
                maxFreq: maxBandFreq
            )
            
            bands[i] = energy
        }
        
        return bands
    }
    
    /// Apply asymmetric attack/decay smoothing
    private func applySmoothing(to target: AudioEnergyData, deltaTime: Float) -> AudioEnergyData {
        // Asymmetric smoothing: fast attack, slow decay
        let attackFactor = 1.0 - exp(-deltaTime / attackTime)
        let decayFactor = 1.0 - exp(-deltaTime / decayTime)
        
        // Smooth intensity
        let smoothedIntensity = smoothValue(
            current: previousIntensity,
            target: target.intensity,
            attackFactor: attackFactor,
            decayFactor: decayFactor
        )
        previousIntensity = smoothedIntensity
        
        // Smooth bass energy
        let smoothedBass = smoothValue(
            current: previousBassEnergy,
            target: target.bassEnergy,
            attackFactor: attackFactor,
            decayFactor: decayFactor
        )
        previousBassEnergy = smoothedBass
        
        // Smooth high energy
        let smoothedHigh = smoothValue(
            current: previousHighEnergy,
            target: target.highEnergy,
            attackFactor: attackFactor,
            decayFactor: decayFactor
        )
        previousHighEnergy = smoothedHigh
        
        // Smooth punch (use faster attack for transients)
        let punchAttackFactor = 1.0 - exp(-deltaTime / 0.01)  // Very fast attack (10ms)
        let smoothedPunch = smoothValue(
            current: previousPunch,
            target: target.punch,
            attackFactor: punchAttackFactor,
            decayFactor: decayFactor
        )
        previousPunch = smoothedPunch
        
        // Smooth frequency bands
        var smoothedBands = [Float](repeating: 0.0, count: bandCount)
        for i in 0..<bandCount {
            smoothedBands[i] = smoothValue(
                current: previousBands[i],
                target: target.frequencyBands[i],
                attackFactor: attackFactor,
                decayFactor: decayFactor
            )
        }
        previousBands = smoothedBands
        
        return AudioEnergyData(
            intensity: smoothedIntensity,
            bassEnergy: smoothedBass,
            highEnergy: smoothedHigh,
            punch: smoothedPunch,
            frequencyBands: smoothedBands,
            timestamp: target.timestamp
        )
    }
    
    /// Smooth a single value with asymmetric attack/decay
    private func smoothValue(current: Float, target: Float, attackFactor: Float, decayFactor: Float) -> Float {
        if target > current {
            // Attack: quick response to increases
            return current + (target - current) * attackFactor
        } else {
            // Decay: slower response to decreases
            return current + (target - current) * decayFactor
        }
    }
    
    /// Clamp value between min and max
    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        return Swift.max(min, Swift.min(max, value))
    }
}
