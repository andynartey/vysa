//
//  NebulaSphereMode.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import simd

/// Volumetric sphere made of particles that expands/contracts and swirls with music
final class NebulaSphereMode: VisualizationMode {
    let id: Int = 0
    let name: String = "Nebula Sphere"
    let description: String = "Volumetric particle sphere that breathes and swirls with the music"
    let iconName: String = "sphere.fill"
    let preferredParticleCount: Int = 100_000
    let supportsHandInteraction: Bool = true
    let recommendedScale: ClosedRange<Float> = 0.5...2.0
    
    func generateBasePositions(particleCount: Int, scale: Float) -> [SIMD3<Float>] {
        var positions = [SIMD3<Float>]()
        positions.reserveCapacity(particleCount)
        
        for _ in 0..<particleCount {
            // Random point inside sphere with density falloff from center
            let point = randomPointInSphere()
            
            // Apply density falloff (more particles toward center)
            let radius = length(point)
            let densityFactor = 1.0 - radius * 0.5
            
            if randomFloat(min: 0, max: 1) < densityFactor {
                positions.append(point * scale * 0.5)
            } else {
                // Retry with different point
                let point2 = randomPointInSphere()
                positions.append(point2 * scale * 0.5)
            }
        }
        
        return positions
    }
    
    func transitionFrom(_ from: [SIMD3<Float>], particleCount: Int, scale: Float) -> [SIMD3<Float>] {
        let newPositions = generateBasePositions(particleCount: particleCount, scale: scale)
        
        // For sphere, add swirl motion during transition
        var transitionPositions = [SIMD3<Float>]()
        transitionPositions.reserveCapacity(particleCount)
        
        for i in 0..<min(from.count, newPositions.count) {
            // Interpolate with rotation
            let angle = Float(i) / Float(particleCount) * .pi * 2
            let rotation = simd_float3x3(
                SIMD3<Float>(cos(angle), 0, sin(angle)),
                SIMD3<Float>(0, 1, 0),
                SIMD3<Float>(-sin(angle), 0, cos(angle))
            )
            
            let rotatedTarget = rotation * newPositions[i]
            transitionPositions.append(rotatedTarget)
        }
        
        return transitionPositions
    }
}
