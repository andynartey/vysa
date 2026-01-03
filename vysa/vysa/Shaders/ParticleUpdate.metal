//
//  ParticleUpdate.metal
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

// Helper: Calculate distance between two points
float distance3(float3 a, float3 b) {
    float3 delta = a - b;
    return sqrt(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z);
}

// Helper: Apply hand dispersion force
float3 calculateHandForce(float3 particlePos, float3 handPos, float handActive, float strength) {
    if (handActive < 0.5) {
        return float3(0.0);
    }
    
    float3 toParticle = particlePos - handPos;
    float dist = length(toParticle);
    
    // Inverse square falloff
    float influenceRadius = 0.3; // 30cm influence radius
    if (dist > influenceRadius) {
        return float3(0.0);
    }
    
    // Force magnitude with inverse square falloff
    float forceMagnitude = strength / max(dist * dist, 0.01);
    float3 forceDirection = normalize(toParticle);
    
    return forceDirection * forceMagnitude;
}

// Particle update compute kernel
kernel void updateParticles(
    device Particle* particles [[buffer(0)]],
    constant ParticleUniforms& uniforms [[buffer(1)]],
    uint id [[thread_position_in_grid]]
) {
    // Bounds check
    if (id >= uniforms.particleCount) {
        return;
    }
    
    device Particle& particle = particles[id];
    
    // Get frequency band for this particle
    uint bandIndex = uint(particle.frequencyBand * 63.0);
    float bandEnergy = uniforms.audioData.frequencyBands[bandIndex];
    
    // Audio-driven displacement based on visualization mode
    float3 audioDisplacement = float3(0.0);
    
    switch (uniforms.visualizationMode) {
        case 0: { // Nebula Sphere
            // Radial expansion based on intensity
            float3 fromCenter = normalize(particle.basePosition);
            float expansion = uniforms.audioData.intensity * 0.2;
            audioDisplacement = fromCenter * expansion;
            
            // Add swirl based on bass
            float swirl = uniforms.audioData.bassEnergy * 0.1;
            float angle = uniforms.time * swirl;
            float s = sin(angle);
            float c = cos(angle);
            audioDisplacement.x += particle.basePosition.y * s * 0.5;
            audioDisplacement.y += particle.basePosition.x * c * 0.5;
            break;
        }
        
        case 1: { // Radial Crown
            // Vertical displacement based on band energy
            audioDisplacement.y = bandEnergy * 0.5;
            
            // Slight rotation on bass
            float rotation = uniforms.audioData.bassEnergy * 0.05;
            audioDisplacement.x += sin(uniforms.time * rotation) * 0.1;
            break;
        }
        
        case 2: { // Terrain Wave
            // Height displacement
            audioDisplacement.y = bandEnergy * 0.4;
            
            // Wave propagation
            float waveSpeed = 2.0;
            float wave = sin(particle.basePosition.x * 3.0 + uniforms.time * waveSpeed);
            audioDisplacement.y += wave * uniforms.audioData.intensity * 0.2;
            break;
        }
        
        case 3: { // Helix DNA
            // Thickness pulsing
            float3 toAxis = particle.basePosition;
            toAxis.y = 0.0;
            float radialDistance = length(toAxis);
            float pulse = uniforms.audioData.intensity * 0.2;
            if (radialDistance > 0.01) {
                audioDisplacement += normalize(toAxis) * pulse;
            }
            
            // Rotation based on bass
            float rotSpeed = uniforms.audioData.bassEnergy * 2.0;
            audioDisplacement.y += sin(uniforms.time * rotSpeed + particle.phase) * 0.1;
            break;
        }
        
        case 4: { // Constellation Network
            // Node pulsing
            float pulse = bandEnergy * 0.3;
            audioDisplacement = normalize(particle.basePosition) * pulse;
            break;
        }
    }
    
    // Calculate target position with audio displacement
    float3 targetPosition = particle.basePosition + audioDisplacement;
    
    // Hand interaction forces
    float3 handForce = float3(0.0);
    handForce += calculateHandForce(
        particle.position,
        uniforms.handData.leftHandPosition,
        uniforms.handData.leftHandActive,
        uniforms.disperseStrength
    );
    handForce += calculateHandForce(
        particle.position,
        uniforms.handData.rightHandPosition,
        uniforms.handData.rightHandActive,
        uniforms.disperseStrength
    );
    
    // Apply hand force to velocity
    particle.velocity += handForce * uniforms.deltaTime;
    
    // Spring force toward target position
    float springStrength = 5.0;
    float3 toTarget = targetPosition - particle.position;
    float3 springForce = toTarget * springStrength;
    
    // Apply spring force
    particle.velocity += springForce * uniforms.deltaTime;
    
    // Damping
    float damping = 0.95;
    particle.velocity *= damping;
    
    // Update position
    particle.position += particle.velocity * uniforms.deltaTime;
    
    // Color based on energy
    float4 baseColor = float4(0.2, 0.3, 0.8, 1.0); // Deep blue base
    
    // Bass shifts to purple/magenta
    float bassInfluence = uniforms.audioData.bassEnergy;
    baseColor.r += bassInfluence * 0.6; // Add red for magenta
    baseColor.b += bassInfluence * 0.2;
    
    // High frequencies shift to cyan/gold
    float highInfluence = uniforms.audioData.highEnergy;
    baseColor.r += highInfluence * 0.5;
    baseColor.g += highInfluence * 0.7;
    
    // Intensity brightens overall
    float brightness = 0.5 + uniforms.audioData.intensity * 0.5;
    baseColor.rgb *= brightness;
    
    // Punch creates white flash
    float punchFlash = uniforms.audioData.punch;
    baseColor.rgb = mix(baseColor.rgb, float3(1.0), punchFlash * 0.5);
    
    // Clamp to valid range
    particle.color = clamp(baseColor, 0.0, 1.0);
    
    // Size pulsing with band energy
    float baseSize = 0.01 * uniforms.scale;
    float sizePulse = 1.0 + bandEnergy * 0.5;
    particle.size = baseSize * sizePulse;
}
