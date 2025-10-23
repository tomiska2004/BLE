//
//  BeaconTag.swift
//  BLE
//
//  Created by Nándor Szőcs on 23.10.2025.
//


// BeaconTag.swift
import Foundation
import CoreBluetooth
import CoreLocation

struct BeaconTag: Identifiable, Hashable {
    let id: UUID          // unique id for this logical tag (not necessarily peripheral UUID)
    let name: String
    let macOrIdentifier: String // optional identifier you use (advertisement local name, manufacturer id, etc)
    let xMeters: Double   // tag coordinate on floorplan (meters)
    let yMeters: Double
    var txPower: Int8     // RSSI at 1m (dBm) - configurable per tag, default e.g. -59
    // transient state
    var lastRSSI: Double? = nil
    var lastDistanceMeters: Double? = nil
}
