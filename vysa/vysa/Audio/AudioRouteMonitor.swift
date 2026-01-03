//
//  AudioRouteMonitor.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import AVFoundation
import Foundation

/// Monitors audio route changes to detect when audio is routed to Bluetooth headphones (AirPods)
@Observable
final class AudioRouteMonitor {
    /// Current audio route type
    enum AudioRoute {
        case speakers      // Vision Pro speakers - visualizer works
        case headphones    // Bluetooth headphones - need fallback mode
        case unknown
    }
    
    /// Current detected audio route
    private(set) var currentRoute: AudioRoute = .unknown
    
    /// Whether the current route supports microphone-based visualization
    var supportsVisualization: Bool {
        currentRoute == .speakers
    }
    
    init() {
        setupNotifications()
        updateCurrentRoute()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Set up notifications for audio route changes
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    /// Handle audio route change notification
    @objc private func handleRouteChange(notification: Notification) {
        updateCurrentRoute()
    }
    
    /// Update the current audio route
    private func updateCurrentRoute() {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        
        // Check if any output is Bluetooth
        let hasBluetoothOutput = outputs.contains { output in
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothHFP ||
            output.portType == .bluetoothLE
        }
        
        if hasBluetoothOutput {
            currentRoute = .headphones
        } else if outputs.contains(where: { $0.portType == .builtInSpeaker }) {
            currentRoute = .speakers
        } else {
            // Default to speakers for unknown routes
            currentRoute = .speakers
        }
    }
    
    /// Get user-friendly description of current route
    var routeDescription: String {
        switch currentRoute {
        case .speakers:
            return "Vision Pro Speakers"
        case .headphones:
            return "Bluetooth Headphones"
        case .unknown:
            return "Unknown Audio Device"
        }
    }
    
    /// Get recommendation message for user
    var recommendationMessage: String? {
        if currentRoute == .headphones {
            return "For the full visualization experience, please switch to Vision Pro speakers. Bluetooth headphones prevent microphone-based audio capture."
        }
        return nil
    }
}
