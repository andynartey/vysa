//
//  ShaderTypes.h
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// Particle structure shared between Swift and Metal
typedef struct {
    simd_float3 position;           // Current world position
    simd_float3 basePosition;       // Rest position (audio-driven target)
    simd_float3 velocity;           // For hand interaction physics
    float frequencyBand;            // Which FFT band (0.0-1.0)
    float phase;                    // Animation offset
    simd_float4 color;              // RGBA color
    float size;                     // Point size, pulses with amplitude
    float _padding;                 // Align to 16 bytes
} Particle;

// Audio energy data for GPU
typedef struct {
    float intensity;                // Overall intensity 0-1
    float bassEnergy;               // Bass energy 0-1
    float highEnergy;               // High energy 0-1
    float punch;                    // Transient punch 0-1
    float frequencyBands[64];       // 64 frequency bands
} AudioEnergyGPU;

// Hand position data for GPU
typedef struct {
    simd_float3 leftHandPosition;   // Left hand world position
    simd_float3 rightHandPosition;  // Right hand world position
    float leftHandActive;           // 1.0 if tracking, 0.0 if not
    float rightHandActive;          // 1.0 if tracking, 0.0 if not
} HandDataGPU;

// Uniforms for particle compute shader
typedef struct {
    float deltaTime;                // Time since last frame
    float time;                     // Total elapsed time
    float scale;                    // Visualizer scale
    unsigned int particleCount;     // Number of particles
    AudioEnergyGPU audioData;       // Audio energy data
    HandDataGPU handData;           // Hand tracking data
    int visualizationMode;          // Current mode (0-4)
    float disperseStrength;         // Hand dispersion strength
} ParticleUniforms;

#endif /* ShaderTypes_h */
