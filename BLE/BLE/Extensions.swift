//
//  Extensions.swift
//  BLE
//
//  Created by Nándor Szőcs on 23.10.2025.
//

import Foundation
import Combine
import CoreBluetooth
import simd
import SwiftUI


// CBCentralManager scanning delegate: implement didDiscover in an extension
extension ScannerViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        func centralManagerDidUpdateState(_ central: CBCentralManager) {
                DispatchQueue.main.async {
                    switch central.state {
                    case .unknown: self.statusMessage = "Bluetooth unknown"
                    case .resetting: self.statusMessage = "Bluetooth resetting"
                    case .unsupported: self.statusMessage = "Bluetooth unsupported"
                    case .unauthorized: self.statusMessage = "Bluetooth unauthorized"
                    case .poweredOff: self.statusMessage = "Bluetooth Off"
                    case .poweredOn: self.statusMessage = "Bluetooth On"
                    @unknown default: self.statusMessage = "Bluetooth unknown state"
                    }
                }
            }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // RSSI is an NSNumber (dBm). Filter out invalid values (like 127)
        let rssiValue = RSSI.doubleValue
        guard rssiValue != 127 else { return }
        processAdvertisement(peripheral: peripheral, rssi: rssiValue, advData: advertisementData)
    }
}
