//
//  TerrainWaveMode.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import simd

/// Deformable grid on horizontal plane with rolling waves
final class TerrainWaveMode: VisualizationMode {
    let id: Int = 2
    let name: String = "Terrain Wave"
    let description: String = "Deformable surface that ripples and flows like water"
    let iconName: String = "water.waves"
    let preferredParticleCount: Int = 120_000
    let supportsHandInteraction: Bool = true
    let recommendedScale: ClosedRange<Float> = 2.0...5.0
    
    func generateBasePositions(particleCount: Int, scale: Float) -> [SIMD3<Float>] {
        var positions = [SIMD3<Float>]()
        positions.reserveCapacity(particleCount)
        
        let gridSize = Int(sqrt(Float(particleCount)))
        let spacing = scale / Float(gridSize)
        let offset = scale * 0.5
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let x = Float(col) * spacing - offset
                let z = Float(row) * spacing - offset
                let y: Float = 0.0  // Flat plane, audio will create waves
                
                positions.append(SIMD3<Float>(x, y, z))
            }
        }
        
        // Fill remaining particles with slight randomization
        while positions.count < particleCount {
            let x = randomFloat(min: -offset, max: offset)
            let z = randomFloat(min: -offset, max: offset)
            positions.append(SIMD3<Float>(x, 0, z))
        }
        
        return positions
    }
}
