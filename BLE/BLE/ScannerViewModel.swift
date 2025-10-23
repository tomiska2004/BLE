//
//  ScannerViewModel.swift
//  BLE
//
//  Created by Nándor Szőcs on 23.10.2025.
//


// ScannerViewModel.swift
import Foundation
import Combine
import CoreBluetooth
import simd
import SwiftUI

final class ScannerViewModel: NSObject, ObservableObject {
    // Public state for UI
    @Published var tags: [BeaconTag] = []
    @Published var userPosition: CGPoint? = nil // pixels on floorplan view; or meters if you prefer
    @Published var isScanning: Bool = false
    @Published var statusMessage: String = "Idle"
    
    // Floorplan mapping
    var floorWidthMeters: Double // room width in meters
    var floorHeightMeters: Double
    var viewWidthPixels: CGFloat = 300 // set from view geometry
    var viewHeightPixels: CGFloat = 300
    
    // BLE
    private var centralManager: CBCentralManager!
    private var rssiCache: [UUID: Double] = [:] // EMA RSSI per tag id
    private var cancellables = Set<AnyCancellable>()
    
    // tuning
    var pathLossExponent: Double = 2.5
    var rssiAlpha: Double = 0.4 // EMA alpha
    
    init(floorWidthMeters: Double, floorHeightMeters: Double, configuredTags: [BeaconTag]) {
        self.floorWidthMeters = floorWidthMeters
        self.floorHeightMeters = floorHeightMeters
        self.tags = configuredTags
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "ble.queue"))
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth not ready"
            return
        }
        isScanning = true
        statusMessage = "Scanning..."
        // Start scanning for peripherals advertising (nil for all)
        // You may want to filter by service UUID or manufacturer data in options.
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        statusMessage = "Stopped"
    }
    
    func processAdvertisement(peripheral: CBPeripheral, rssi: Double, advData: [String: Any]) {
        // Identify which tag this is: by name, manufacturer data, or peripheral.identifier.
        // For simplicity, match by peripheral.identifier.uuidString or local name in advData.
        let identifier = peripheral.identifier.uuidString
        
        // Try find tag by macOrIdentifier match
        guard let index = tags.firstIndex(where: { $0.macOrIdentifier == identifier || $0.name == advData[CBAdvertisementDataLocalNameKey] as? String }) else {
            return
        }
        // EMA smoothing
        let prev = rssiCache[tags[index].id] // keyed by logical tag id
        let smoothed = RSSIConverter.ema(previous: prev, newSample: rssi, alpha: rssiAlpha)
        rssiCache[tags[index].id] = smoothed
        // Update tag state
        tags[index].lastRSSI = smoothed
        let dist = RSSIConverter.distanceFrom(rssi: smoothed, txPower: Double(tags[index].txPower), pathLossExponent: pathLossExponent)
        tags[index].lastDistanceMeters = dist
        
        // Attempt trilateration if we have 3 tags with distances
        let validTags = tags.filter { $0.lastDistanceMeters != nil }
        if validTags.count >= 3 {
            // select three (for now first 3)
            let t1 = validTags[0]
            let t2 = validTags[1]
            let t3 = validTags[2]
            let p1 = SIMD2<Double>(t1.xMeters, t1.yMeters)
            let p2 = SIMD2<Double>(t2.xMeters, t2.yMeters)
            let p3 = SIMD2<Double>(t3.xMeters, t3.yMeters)
            if let point = trilaterate(p1: p1, r1: t1.lastDistanceMeters!,
                                       p2: p2, r2: t2.lastDistanceMeters!,
                                       p3: p3, r3: t3.lastDistanceMeters!) {
                // Convert meters -> pixels for UI
                let px = mapXMetersToPixel(xMeters: point.x)
                let py = mapYMetersToPixel(yMeters: point.y)
                DispatchQueue.main.async {
                    self.userPosition = CGPoint(x: px, y: py)
                    self.statusMessage = String(format: "Position: (%.2f m, %.2f m)", point.x, point.y)
                }
            }
        }
    }
    
    // Map floorplan meters -> pixel coordinates (origin top-left)
    func mapXMetersToPixel(xMeters: Double) -> CGFloat {
        return CGFloat(xMeters / floorWidthMeters) * viewWidthPixels
    }
    func mapYMetersToPixel(yMeters: Double) -> CGFloat {
        // depending on coordinate origin of floorplan: assume y increases downward
        return CGFloat(yMeters / floorHeightMeters) * viewHeightPixels
    }
}

//extension ScannerViewModel: CBCentralManagerDelegate {
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        DispatchQueue.main.async {
//            switch central.state {
//            case .unknown: self.statusMessage = "Bluetooth unknown"
//            case .resetting: self.statusMessage = "Bluetooth resetting"
//            case .unsupported: self.statusMessage = "Bluetooth unsupported"
//            case .unauthorized: self.statusMessage = "Bluetooth unauthorized"
//            case .poweredOff: self.statusMessage = "Bluetooth Off"
//            case .poweredOn: self.statusMessage = "Bluetooth On"
//            @unknown default: self.statusMessage = "Bluetooth unknown state"
//            }
//        }
//    }
//}

extension ScannerViewModel: CBPeripheralDelegate {
    // If you connect, handle peripheral delegate calls here
}

func trilaterate(p1: SIMD2<Double>, r1: Double,
                 p2: SIMD2<Double>, r2: Double,
                 p3: SIMD2<Double>, r3: Double) -> SIMD2<Double>? {
    let x1 = p1.x, y1 = p1.y
    let x2 = p2.x, y2 = p2.y
    let x3 = p3.x, y3 = p3.y

    let A = 2*(x2 - x1)
    let B = 2*(y2 - y1)
    let C = r1*r1 - r2*r2 - x1*x1 + x2*x2 - y1*y1 + y2*y2
    let D = 2*(x3 - x2)
    let E = 2*(y3 - y2)
    let F = r2*r2 - r3*r3 - x2*x2 + x3*x3 - y2*y2 + y3*y3

    let denom = A*E - B*D
    if abs(denom) < 1e-8 {
        // Degenerate or nearly colinear; can't solve reliably
        return nil
    }

    let x = (C*E - B*F) / denom
    let y = (A*F - C*D) / denom
    return SIMD2<Double>(x, y)
}
