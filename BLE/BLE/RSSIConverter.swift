//
//  RSSIConverter.swift
//  BLE
//
//  Created by Nándor Szőcs on 23.10.2025.
//


// RSSIConverter.swift
import Foundation

struct RSSIConverter {
    // Convert RSSI (dBm) to distance (meters) using log-distance path-loss model
    // txPower: RSSI at 1 m (dBm). n: path-loss exponent (typical 2..4)
    static func distanceFrom(rssi: Double, txPower: Double = -59, pathLossExponent n: Double = 2.5) -> Double {
        // distance = 10 ^ ((txPower - rssi) / (10 * n))
        let exponent = (txPower - rssi) / (10.0 * n)
        return pow(10.0, exponent)
    }
    
    // Simple EMA smoothing of RSSI
    static func ema(previous: Double?, newSample: Double, alpha: Double = 0.4) -> Double {
        guard let prev = previous else { return newSample }
        return alpha * newSample + (1.0 - alpha) * prev
    }
}
