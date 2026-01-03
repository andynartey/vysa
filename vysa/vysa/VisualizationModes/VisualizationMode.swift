//
//  VisualizationMode.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import simd

/// Protocol defining a visualization mode with extensible architecture
protocol VisualizationMode: AnyObject {
    /// Unique identifier for the mode
    var id: Int { get }
    
    /// Display name for the mode
    var name: String { get }
    
    /// Description of the mode
    var description: String { get }
    
    /// SF Symbol icon name
    var iconName: String { get }
    
    /// Recommended particle count for this mode
    var preferredParticleCount: Int { get }
    
    /// Whether this mode supports hand interaction
    var supportsHandInteraction: Bool { get }
    
    /// Recommended scale range in meters
    var recommendedScale: ClosedRange<Float> { get }
    
    /// Generate base positions for particles in this mode
    /// - Parameters:
    ///   - particleCount: Number of particles to generate
    ///   - scale: Scale factor for the visualization
    /// - Returns: Array of base positions in 3D space
    func generateBasePositions(particleCount: Int, scale: Float) -> [SIMD3<Float>]
    
    /// Calculate smooth transition positions when morphing from another mode
    /// - Parameters:
    ///   - from: Previous base positions
    ///   - particleCount: Number of particles
    ///   - scale: Current scale
    /// - Returns: New base positions with smooth transition
    func transitionFrom(_ from: [SIMD3<Float>], particleCount: Int, scale: Float) -> [SIMD3<Float>]
}

// Default implementation for transition
extension VisualizationMode {
    func transitionFrom(_ from: [SIMD3<Float>], particleCount: Int, scale: Float) -> [SIMD3<Float>] {
        // By default, just generate new positions
        // Individual modes can override for custom transitions
        return generateBasePositions(particleCount: particleCount, scale: scale)
    }
}

// MARK: - Helper Functions

extension VisualizationMode {
    /// Generate random float between min and max
    func randomFloat(min: Float, max: Float) -> Float {
        return Float.random(in: min...max)
    }
    
    /// Generate random point on unit sphere surface
    func randomPointOnSphere() -> SIMD3<Float> {
        let theta = randomFloat(min: 0, max: .pi * 2)
        let phi = acos(randomFloat(min: -1, max: 1))
        
        let x = sin(phi) * cos(theta)
        let y = sin(phi) * sin(theta)
        let z = cos(phi)
        
        return SIMD3<Float>(x, y, z)
    }
    
    /// Generate random point inside unit sphere
    func randomPointInSphere() -> SIMD3<Float> {
        let point = randomPointOnSphere()
        let radius = pow(randomFloat(min: 0, max: 1), 1.0 / 3.0) // Uniform volume distribution
        return point * radius
    }
}
