//
//  AudioEnergyData.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation

/// Represents the four energy dimensions extracted from audio FFT analysis
struct AudioEnergyData {
    /// Overall audio intensity (full spectrum RMS) - 0.0 to 1.0
    var intensity: Float
    
    /// Bass energy (20-250 Hz) - 0.0 to 1.0
    var bassEnergy: Float
    
    /// High frequency energy (4-16 kHz) - 0.0 to 1.0
    var highEnergy: Float
    
    /// Transient punch (amplitude delta) - 0.0 to 1.0
    var punch: Float
    
    /// 64 logarithmic frequency bands for detailed visualization
    var frequencyBands: [Float]
    
    /// Timestamp when this data was captured
    var timestamp: TimeInterval
    
    /// Creates a silent/zero energy state
    static var zero: AudioEnergyData {
        AudioEnergyData(
            intensity: 0.0,
            bassEnergy: 0.0,
            highEnergy: 0.0,
            punch: 0.0,
            frequencyBands: Array(repeating: 0.0, count: 64),
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    /// Smoothly interpolates between two energy states
    func lerp(to target: AudioEnergyData, factor: Float) -> AudioEnergyData {
        let clampedFactor = max(0.0, min(1.0, factor))
        
        var smoothedBands = [Float]()
        for i in 0..<min(frequencyBands.count, target.frequencyBands.count) {
            let smoothed = frequencyBands[i] + (target.frequencyBands[i] - frequencyBands[i]) * clampedFactor
            smoothedBands.append(smoothed)
        }
        
        return AudioEnergyData(
            intensity: intensity + (target.intensity - intensity) * clampedFactor,
            bassEnergy: bassEnergy + (target.bassEnergy - bassEnergy) * clampedFactor,
            highEnergy: highEnergy + (target.highEnergy - highEnergy) * clampedFactor,
            punch: punch + (target.punch - punch) * clampedFactor,
            frequencyBands: smoothedBands,
            timestamp: target.timestamp
        )
    }
}
