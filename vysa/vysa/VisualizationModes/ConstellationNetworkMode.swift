//
//  ConstellationNetworkMode.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import simd

/// Semi-random nodes forming an abstract network with glowing connections
final class ConstellationNetworkMode: VisualizationMode {
    let id: Int = 4
    let name: String = "Constellation Network"
    let description: String = "Abstract network of connected nodes that pulse with energy"
    let iconName: String = "network"
    let preferredParticleCount: Int = 50_000
    let supportsHandInteraction: Bool = true
    let recommendedScale: ClosedRange<Float> = 0.5...3.0
    
    func generateBasePositions(particleCount: Int, scale: Float) -> [SIMD3<Float>] {
        var positions = [SIMD3<Float>]()
        positions.reserveCapacity(particleCount)
        
        // Create main nodes distributed in 3D space
        let nodeCount = min(particleCount / 100, 200)  // Up to 200 major nodes
        var nodes = [SIMD3<Float>]()
        
        for _ in 0..<nodeCount {
            let node = randomPointInSphere() * scale * 0.5
            nodes.append(node)
            positions.append(node)
        }
        
        // Fill space with particles, clustering around nodes
        let particlesPerNode = (particleCount - nodeCount) / nodeCount
        
        for node in nodes {
            for _ in 0..<particlesPerNode {
                // Particles orbit or trail from nodes
                let offset = randomPointInSphere() * scale * 0.1
                positions.append(node + offset)
            }
        }
        
        // Fill any remaining particles
        while positions.count < particleCount {
            let randomNode = nodes.randomElement() ?? SIMD3<Float>(0, 0, 0)
            let offset = randomPointInSphere() * scale * 0.15
            positions.append(randomNode + offset)
        }
        
        return positions
    }
    
    func transitionFrom(_ from: [SIMD3<Float>], particleCount: Int, scale: Float) -> [SIMD3<Float>] {
        let newPositions = generateBasePositions(particleCount: particleCount, scale: scale)
        
        // For constellation, particles should collapse to nodes then expand
        var transitionPositions = [SIMD3<Float>]()
        transitionPositions.reserveCapacity(particleCount)
        
        for i in 0..<min(from.count, newPositions.count) {
            // Add slight convergence toward center before dispersing
            let toCenter = -from[i] * 0.1
            transitionPositions.append(newPositions[i] + toCenter)
        }
        
        return transitionPositions
    }
}
