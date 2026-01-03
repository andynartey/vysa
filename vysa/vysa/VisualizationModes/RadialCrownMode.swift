//
//  RadialCrownMode.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import simd

/// Concentric rings radiating outward - classic circular spectrum analyzer in 3D
final class RadialCrownMode: VisualizationMode {
    let id: Int = 1
    let name: String = "Radial Crown"
    let description: String = "Concentric rings with vertical displacement based on frequency"
    let iconName: String = "circle.hexagongrid.fill"
    let preferredParticleCount: Int = 80_000
    let supportsHandInteraction: Bool = true
    let recommendedScale: ClosedRange<Float> = 0.3...1.0
    
    func generateBasePositions(particleCount: Int, scale: Float) -> [SIMD3<Float>] {
        var positions = [SIMD3<Float>]()
        positions.reserveCapacity(particleCount)
        
        let ringCount = 64  // Match frequency bands
        let particlesPerRing = particleCount / ringCount
        
        for ring in 0..<ringCount {
            let normalizedRing = Float(ring) / Float(ringCount)
            let radius = normalizedRing * scale * 0.5
            
            for particle in 0..<particlesPerRing {
                let angle = Float(particle) / Float(particlesPerRing) * .pi * 2
                
                let x = cos(angle) * radius
                let z = sin(angle) * radius
                let y: Float = 0.0  // Start flat, audio will displace vertically
                
                positions.append(SIMD3<Float>(x, y, z))
            }
        }
        
        // Fill remaining particles
        while positions.count < particleCount {
            let ring = Int.random(in: 0..<ringCount)
            let normalizedRing = Float(ring) / Float(ringCount)
            let radius = normalizedRing * scale * 0.5
            let angle = randomFloat(min: 0, max: .pi * 2)
            
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            
            positions.append(SIMD3<Float>(x, 0, z))
        }
        
        return positions
    }
}
