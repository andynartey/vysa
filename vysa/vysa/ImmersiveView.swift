//
//  ImmersiveView.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import SwiftUI
import RealityKit
import RealityKitContent

/// Component to tag entities that need particle updates
struct ParticleUpdateComponent: Component {
    var particleSystem: ParticleSystemRenderer
    var particleEntities: [Entity]
}

/// System that runs every frame to update particles
struct ParticleUpdateSystem: System {
    static let query = EntityQuery(where: .has(ParticleUpdateComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let component = entity.components[ParticleUpdateComponent.self] else { continue }
            
            // Update particle system
            Task { @MainActor in
                component.particleSystem.update()
            }
            
            // Apply rotation to container
            let rotationSpeed: Float = 0.3
            let rotation = simd_quatf(angle: rotationSpeed * Float(context.deltaTime), axis: [0, 1, 0])
            entity.orientation *= rotation
            
            // Get updated particles
            let particles = component.particleSystem.getParticles()
            
            // Update each visible entity
            for (index, particleEntity) in component.particleEntities.enumerated() {
                let particleIndex = index * 10
                if particleIndex < particles.count {
                    let particle = particles[particleIndex]
                    
                    // Update position
                    particleEntity.position = particle.position
                    
                    // Update scale
                    let scale = particle.size / 0.01
                    particleEntity.scale = [scale, scale, scale]
                    
                    // Update color (simplified - just update material tint)
                    if var modelEntity = particleEntity as? ModelEntity {
                        var material = SimpleMaterial()
                        material.color = .init(
                            tint: .init(
                                red: Double(particle.color.x),
                                green: Double(particle.color.y),
                                blue: Double(particle.color.z),
                                alpha: Double(particle.color.w)
                            )
                        )
                        modelEntity.model?.materials = [material]
                    }
                }
            }
        }
    }
}

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
            // Register the update system
            ParticleUpdateSystem.registerSystem()
            
            // Create particle system
            let system = ParticleSystemRenderer(particleCount: 10_000, scale: 1.0)
            
            // Create container entity
            let container = Entity()
            container.position = [0, 1.5, -2.0]
            
            // Create particle entities
            var entities: [Entity] = []
            let particles = system.getParticles()
            
            for i in stride(from: 0, to: particles.count, by: 10) {
                let particle = particles[i]
                
                let mesh = MeshResource.generateSphere(radius: particle.size)
                var material = SimpleMaterial()
                material.color = .init(
                    tint: .init(
                        red: Double(particle.color.x),
                        green: Double(particle.color.y),
                        blue: Double(particle.color.z),
                        alpha: Double(particle.color.w)
                    )
                )
                
                let entity = ModelEntity(mesh: mesh, materials: [material])
                entity.position = particle.position
                
                container.addChild(entity)
                entities.append(entity)
            }
            
            // Add update component to container
            container.components[ParticleUpdateComponent.self] = ParticleUpdateComponent(
                particleSystem: system,
                particleEntities: entities
            )
            
            content.add(container)
            
            print("✅ Created \(entities.count) particles with update system")
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    if let entity = value.entity.parent,
                       let component = entity.components[ParticleUpdateComponent.self] {
                        Task { @MainActor in
                            component.particleSystem.nextMode()
                        }
                    }
                }
        )
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
