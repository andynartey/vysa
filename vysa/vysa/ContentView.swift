//
//  ContentView.swift
//  vysa
//
//  Created by Andy on 02/01/2026.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 20) {
            Text("VYSA")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            
            Text("Audio-Reactive Particle Visualizer")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(spacing: 16) {
                Text("Enter the immersive space to see audio-reactive particles")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ToggleImmersiveSpaceButton()
                
                if appModel.immersiveSpaceState == .open {
                    VStack(spacing: 12) {
                        Text("Controls")
                            .font(.headline)
                        
                        Text("• Tap anywhere to switch visualization modes")
                        Text("• Play audio to see particles react")
                        Text("• 5 unique visualization patterns available")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environment(AppModel())
}
