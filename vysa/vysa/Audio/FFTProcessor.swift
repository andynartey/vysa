//
//  FFTProcessor.swift
//  vysa
//
//  Created by Andrew Nartey on 02/01/2026.
//

import Accelerate
import Foundation

/// Performs Fast Fourier Transform on audio buffers using vDSP for efficient frequency analysis
final class FFTProcessor {
    // FFT Configuration
    private let fftSize: Int = 1024  // 1024-point FFT for balance between resolution and latency
    private let log2n: vDSP_Length
    private let fftSetup: FFTSetup
    
    // Buffers for vDSP operations
    private var realBuffer: [Float]
    private var imagBuffer: [Float]
    private var splitComplex: DSPSplitComplex
    private var magnitudes: [Float]
    
    // Window function for reducing spectral leakage
    private var window: [Float]
    
    // Sample rate
    let sampleRate: Double = 44100.0
    
    init() {
        self.log2n = vDSP_Length(log2(Float(fftSize)))
        
        // Create FFT setup (expensive operation, done once)
        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            fatalError("Failed to create FFT setup")
        }
        self.fftSetup = setup
        
        // Allocate buffers
        self.realBuffer = [Float](repeating: 0.0, count: fftSize)
        self.imagBuffer = [Float](repeating: 0.0, count: fftSize)
        self.magnitudes = [Float](repeating: 0.0, count: fftSize / 2)
        
        // Create split complex structure
        self.splitComplex = DSPSplitComplex(
            realp: UnsafeMutablePointer(&realBuffer),
            imagp: UnsafeMutablePointer(&imagBuffer)
        )
        
        // Create Hann window to reduce spectral leakage
        self.window = [Float](repeating: 0.0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
    }
    
    deinit {
        vDSP_destroy_fftsetup(fftSetup)
    }
    
    /// Process audio buffer and return frequency magnitudes
    /// - Parameter audioBuffer: Input audio samples (expects at least fftSize samples)
    /// - Returns: Array of magnitude values for each frequency bin
    func process(audioBuffer: [Float]) -> [Float] {
        guard audioBuffer.count >= fftSize else {
            return magnitudes  // Return previous magnitudes if buffer too small
        }
        
        // Apply window function to reduce spectral leakage
        var windowedBuffer = [Float](repeating: 0.0, count: fftSize)
        vDSP_vmul(audioBuffer, 1, window, 1, &windowedBuffer, 1, vDSP_Length(fftSize))
        
        // Convert to split complex format (interleaved real/imag to separate arrays)
        windowedBuffer.withUnsafeBytes { bufferPtr in
            guard let baseAddress = bufferPtr.baseAddress?.assumingMemoryBound(to: Float.self) else {
                return
            }
            
            // Pack real data into split complex
            realBuffer.withUnsafeMutableBufferPointer { realPtr in
                imagBuffer.withUnsafeMutableBufferPointer { imagPtr in
                    var complex = DSPSplitComplex(
                        realp: realPtr.baseAddress!,
                        imagp: imagPtr.baseAddress!
                    )
                    
                    // Convert real samples to complex format
                    baseAddress.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &complex, 1, vDSP_Length(fftSize / 2))
                    }
                }
            }
        }
        
        // Perform forward FFT
        realBuffer.withUnsafeMutableBufferPointer { realPtr in
            imagBuffer.withUnsafeMutableBufferPointer { imagPtr in
                var complex = DSPSplitComplex(
                    realp: realPtr.baseAddress!,
                    imagp: imagPtr.baseAddress!
                )
                vDSP_fft_zrip(fftSetup, &complex, 1, log2n, FFTDirection(FFT_FORWARD))
            }
        }
        
        // Calculate magnitudes from real and imaginary components
        realBuffer.withUnsafeBufferPointer { realPtr in
            imagBuffer.withUnsafeBufferPointer { imagPtr in
                var complex = DSPSplitComplex(
                    realp: UnsafeMutablePointer(mutating: realPtr.baseAddress!),
                    imagp: UnsafeMutablePointer(mutating: imagPtr.baseAddress!)
                )
                
                // Compute magnitudes: sqrt(real^2 + imag^2)
                vDSP_zvabs(&complex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
            }
        }
        
        // Normalize magnitudes
        var scale = Float(2.0) / Float(fftSize)
        vDSP_vsmul(magnitudes, 1, &scale, &magnitudes, 1, vDSP_Length(fftSize / 2))
        
        return magnitudes
    }
    
    /// Convert FFT bin index to frequency in Hz
    func binToFrequency(_ bin: Int) -> Double {
        return Double(bin) * sampleRate / Double(fftSize)
    }
    
    /// Convert frequency in Hz to FFT bin index
    func frequencyToBin(_ frequency: Double) -> Int {
        return Int(frequency * Double(fftSize) / sampleRate)
    }
    
    /// Get magnitude in a specific frequency range
    func getMagnitudeInRange(magnitudes: [Float], minFreq: Double, maxFreq: Double) -> Float {
        let minBin = max(0, frequencyToBin(minFreq))
        let maxBin = min(magnitudes.count - 1, frequencyToBin(maxFreq))
        
        guard minBin < maxBin else { return 0.0 }
        
        // Calculate RMS of magnitudes in range
        var sum: Float = 0.0
        vDSP_sve(Array(magnitudes[minBin...maxBin]), 1, &sum, vDSP_Length(maxBin - minBin + 1))
        
        return sum / Float(maxBin - minBin + 1)
    }
}
