//
//  ParticleData.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Foundation
import simd

/// Swift representation of Particle structure (matches Metal struct in ShaderTypes.h)
struct ParticleData {
    var position: SIMD3<Float>
    var basePosition: SIMD3<Float>
    var velocity: SIMD3<Float>
    var frequencyBand: Float
    var phase: Float
    var color: SIMD4<Float>
    var size: Float
    var padding: Float  // Alignment padding
    
    init(basePosition: SIMD3<Float>, frequencyBand: Float) {
        self.position = basePosition
        self.basePosition = basePosition
        self.velocity = SIMD3<Float>(0, 0, 0)
        self.frequencyBand = frequencyBand
        self.phase = Float.random(in: 0...(2 * .pi))
        self.color = SIMD4<Float>(0.2, 0.3, 0.8, 1.0)  // Default blue
        self.size = 0.01
        self.padding = 0.0
    }
}

/// Audio energy data for GPU (matches ShaderTypes.h)
/// Using array instead of tuple for predictable memory layout
struct AudioEnergyGPUData {
    var intensity: Float
    var bassEnergy: Float
    var highEnergy: Float
    var punch: Float
    var band0: Float = 0, band1: Float = 0, band2: Float = 0, band3: Float = 0
    var band4: Float = 0, band5: Float = 0, band6: Float = 0, band7: Float = 0
    var band8: Float = 0, band9: Float = 0, band10: Float = 0, band11: Float = 0
    var band12: Float = 0, band13: Float = 0, band14: Float = 0, band15: Float = 0
    var band16: Float = 0, band17: Float = 0, band18: Float = 0, band19: Float = 0
    var band20: Float = 0, band21: Float = 0, band22: Float = 0, band23: Float = 0
    var band24: Float = 0, band25: Float = 0, band26: Float = 0, band27: Float = 0
    var band28: Float = 0, band29: Float = 0, band30: Float = 0, band31: Float = 0
    var band32: Float = 0, band33: Float = 0, band34: Float = 0, band35: Float = 0
    var band36: Float = 0, band37: Float = 0, band38: Float = 0, band39: Float = 0
    var band40: Float = 0, band41: Float = 0, band42: Float = 0, band43: Float = 0
    var band44: Float = 0, band45: Float = 0, band46: Float = 0, band47: Float = 0
    var band48: Float = 0, band49: Float = 0, band50: Float = 0, band51: Float = 0
    var band52: Float = 0, band53: Float = 0, band54: Float = 0, band55: Float = 0
    var band56: Float = 0, band57: Float = 0, band58: Float = 0, band59: Float = 0
    var band60: Float = 0, band61: Float = 0, band62: Float = 0, band63: Float = 0
    
    init() {
        self.intensity = 0
        self.bassEnergy = 0
        self.highEnergy = 0
        self.punch = 0
    }
    
    init(from audioEnergy: AudioEnergyData) {
        self.intensity = audioEnergy.intensity
        self.bassEnergy = audioEnergy.bassEnergy
        self.highEnergy = audioEnergy.highEnergy
        self.punch = audioEnergy.punch
        
        let bands = audioEnergy.frequencyBands
        self.band0 = bands.indices.contains(0) ? bands[0] : 0
        self.band1 = bands.indices.contains(1) ? bands[1] : 0
        self.band2 = bands.indices.contains(2) ? bands[2] : 0
        self.band3 = bands.indices.contains(3) ? bands[3] : 0
        self.band4 = bands.indices.contains(4) ? bands[4] : 0
        self.band5 = bands.indices.contains(5) ? bands[5] : 0
        self.band6 = bands.indices.contains(6) ? bands[6] : 0
        self.band7 = bands.indices.contains(7) ? bands[7] : 0
        self.band8 = bands.indices.contains(8) ? bands[8] : 0
        self.band9 = bands.indices.contains(9) ? bands[9] : 0
        self.band10 = bands.indices.contains(10) ? bands[10] : 0
        self.band11 = bands.indices.contains(11) ? bands[11] : 0
        self.band12 = bands.indices.contains(12) ? bands[12] : 0
        self.band13 = bands.indices.contains(13) ? bands[13] : 0
        self.band14 = bands.indices.contains(14) ? bands[14] : 0
        self.band15 = bands.indices.contains(15) ? bands[15] : 0
        self.band16 = bands.indices.contains(16) ? bands[16] : 0
        self.band17 = bands.indices.contains(17) ? bands[17] : 0
        self.band18 = bands.indices.contains(18) ? bands[18] : 0
        self.band19 = bands.indices.contains(19) ? bands[19] : 0
        self.band20 = bands.indices.contains(20) ? bands[20] : 0
        self.band21 = bands.indices.contains(21) ? bands[21] : 0
        self.band22 = bands.indices.contains(22) ? bands[22] : 0
        self.band23 = bands.indices.contains(23) ? bands[23] : 0
        self.band24 = bands.indices.contains(24) ? bands[24] : 0
        self.band25 = bands.indices.contains(25) ? bands[25] : 0
        self.band26 = bands.indices.contains(26) ? bands[26] : 0
        self.band27 = bands.indices.contains(27) ? bands[27] : 0
        self.band28 = bands.indices.contains(28) ? bands[28] : 0
        self.band29 = bands.indices.contains(29) ? bands[29] : 0
        self.band30 = bands.indices.contains(30) ? bands[30] : 0
        self.band31 = bands.indices.contains(31) ? bands[31] : 0
        self.band32 = bands.indices.contains(32) ? bands[32] : 0
        self.band33 = bands.indices.contains(33) ? bands[33] : 0
        self.band34 = bands.indices.contains(34) ? bands[34] : 0
        self.band35 = bands.indices.contains(35) ? bands[35] : 0
        self.band36 = bands.indices.contains(36) ? bands[36] : 0
        self.band37 = bands.indices.contains(37) ? bands[37] : 0
        self.band38 = bands.indices.contains(38) ? bands[38] : 0
        self.band39 = bands.indices.contains(39) ? bands[39] : 0
        self.band40 = bands.indices.contains(40) ? bands[40] : 0
        self.band41 = bands.indices.contains(41) ? bands[41] : 0
        self.band42 = bands.indices.contains(42) ? bands[42] : 0
        self.band43 = bands.indices.contains(43) ? bands[43] : 0
        self.band44 = bands.indices.contains(44) ? bands[44] : 0
        self.band45 = bands.indices.contains(45) ? bands[45] : 0
        self.band46 = bands.indices.contains(46) ? bands[46] : 0
        self.band47 = bands.indices.contains(47) ? bands[47] : 0
        self.band48 = bands.indices.contains(48) ? bands[48] : 0
        self.band49 = bands.indices.contains(49) ? bands[49] : 0
        self.band50 = bands.indices.contains(50) ? bands[50] : 0
        self.band51 = bands.indices.contains(51) ? bands[51] : 0
        self.band52 = bands.indices.contains(52) ? bands[52] : 0
        self.band53 = bands.indices.contains(53) ? bands[53] : 0
        self.band54 = bands.indices.contains(54) ? bands[54] : 0
        self.band55 = bands.indices.contains(55) ? bands[55] : 0
        self.band56 = bands.indices.contains(56) ? bands[56] : 0
        self.band57 = bands.indices.contains(57) ? bands[57] : 0
        self.band58 = bands.indices.contains(58) ? bands[58] : 0
        self.band59 = bands.indices.contains(59) ? bands[59] : 0
        self.band60 = bands.indices.contains(60) ? bands[60] : 0
        self.band61 = bands.indices.contains(61) ? bands[61] : 0
        self.band62 = bands.indices.contains(62) ? bands[62] : 0
        self.band63 = bands.indices.contains(63) ? bands[63] : 0
    }
}

/// Hand data for GPU (matches ShaderTypes.h)
struct HandDataGPUData {
    var leftHandPosition: SIMD3<Float>
    var rightHandPosition: SIMD3<Float>
    var leftHandActive: Float
    var rightHandActive: Float
    
    init() {
        self.leftHandPosition = SIMD3<Float>(0, 0, 0)
        self.rightHandPosition = SIMD3<Float>(0, 0, 0)
        self.leftHandActive = 0
        self.rightHandActive = 0
    }
}

/// GPU uniforms for particle compute shader (matches ShaderTypes.h)
struct ParticleUniformsData {
    var deltaTime: Float
    var time: Float
    var scale: Float
    var particleCount: UInt32
    var audioData: AudioEnergyGPUData
    var handData: HandDataGPUData
    var visualizationMode: Int32
    var disperseStrength: Float
}
