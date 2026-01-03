//
//  HelixDNAMode.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import simd

/// Double helix spiraling upward on vertical axis
final class HelixDNAMode: VisualizationMode {
    let id: Int = 3
    let name: String = "Helix DNA"
    let description: String = "Double helix spiral with pulsing strands"
    let iconName: String = "person.badge.shield.checkmark.fill"
    let preferredParticleCount: Int = 60_000
    let supportsHandInteraction: Bool = true
    let recommendedScale: ClosedRange<Float> = 0.5...2.0
    
    func generateBasePositions(particleCount: Int, scale: Float) -> [SIMD3<Float>] {
        var positions = [SIMD3<Float>]()
        positions.reserveCapacity(particleCount)
        
        let particlesPerStrand = particleCount / 2
        let height = scale * 2.0
        let radius = scale * 0.2
        let turns: Float = 4.0  // Number of complete rotations
        
        // First strand
        for i in 0..<particlesPerStrand {
            let t = Float(i) / Float(particlesPerStrand)
            let angle = t * turns * .pi * 2
            
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let y = (t - 0.5) * height
            
            positions.append(SIMD3<Float>(x, y, z))
        }
        
        // Second strand (opposite phase)
        for i in 0..<particlesPerStrand {
            let t = Float(i) / Float(particlesPerStrand)
            let angle = t * turns * .pi * 2 + .pi  // 180 degree offset
            
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            let y = (t - 0.5) * height
            
            positions.append(SIMD3<Float>(x, y, z))
        }
        
        return positions
    }
}
