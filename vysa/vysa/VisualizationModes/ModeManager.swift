//
//  ModeManager.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import simd

/// Manages visualization modes with extensible registry pattern
@Observable
final class ModeManager {
    // Registry of all available modes
    private(set) var modes: [VisualizationMode] = []
    
    // Current active mode
    private(set) var currentMode: VisualizationMode
    
    // Transition state
    private(set) var isTransitioning: Bool = false
    var transitionProgress: Float = 0.0
    
    init() {
        // Register all visualization modes
        // These are organized in separate files for clarity
        let allModes: [VisualizationMode] = [
            NebulaSphereMode(),
            RadialCrownMode(),
            TerrainWaveMode(),
            HelixDNAMode(),
            ConstellationNetworkMode()
        ]
        
        self.modes = allModes
        self.currentMode = allModes[0]  // Start with Nebula Sphere
    }
    
    /// Switch to a different visualization mode
    /// - Parameters:
    ///   - mode: The mode to switch to
    ///   - animated: Whether to animate the transition
    func switchTo(mode: VisualizationMode, animated: Bool = true) {
        guard mode.id != currentMode.id else { return }
        
        if animated {
            isTransitioning = true
            transitionProgress = 0.0
        }
        
        currentMode = mode
        
        print("Switching to mode: \(mode.name)")
    }
    
    /// Switch to next mode in the list
    func nextMode() {
        guard let currentIndex = modes.firstIndex(where: { $0.id == currentMode.id }) else {
            return
        }
        
        let nextIndex = (currentIndex + 1) % modes.count
        switchTo(mode: modes[nextIndex], animated: true)
    }
    
    /// Switch to previous mode in the list
    func previousMode() {
        guard let currentIndex = modes.firstIndex(where: { $0.id == currentMode.id }) else {
            return
        }
        
        let previousIndex = (currentIndex - 1 + modes.count) % modes.count
        switchTo(mode: modes[previousIndex], animated: true)
    }
    
    /// Get mode by ID
    func getMode(by id: Int) -> VisualizationMode? {
        return modes.first { $0.id == id }
    }
    
    /// Update transition progress (called per frame during transitions)
    func updateTransition(deltaTime: Float) {
        guard isTransitioning else { return }
        
        // 1 second transition duration
        transitionProgress += deltaTime
        
        if transitionProgress >= 1.0 {
            isTransitioning = false
            transitionProgress = 1.0
        }
    }
    
    /// Get current mode's recommended particle count based on scale
    func getRecommendedParticleCount(for scale: Float) -> Int {
        let baseCount = currentMode.preferredParticleCount
        
        // Adjust particle count based on scale
        let scaleFactor = scale / 1.0  // 1.0m is base scale
        let adjustedCount = Int(Float(baseCount) * scaleFactor)
        
        // Clamp to reasonable bounds
        return min(max(adjustedCount, 10_000), 1_000_000)
    }
    
    /// Check if current mode is within its recommended scale range
    func isScaleOptimal(for scale: Float) -> Bool {
        return currentMode.recommendedScale.contains(scale)
    }
    
    /// Get warning message if scale is not optimal
    func getScaleWarning(for scale: Float) -> String? {
        if scale < currentMode.recommendedScale.lowerBound {
            return "\(currentMode.name) works best at larger scales. Try \(currentMode.recommendedScale.lowerBound)m or larger."
        } else if scale > currentMode.recommendedScale.upperBound {
            return "\(currentMode.name) works best at smaller scales. Try \(currentMode.recommendedScale.upperBound)m or smaller."
        }
        return nil
    }
}
