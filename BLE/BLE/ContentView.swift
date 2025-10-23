//
//  ContentView.swift
//  BLE
//
//  Created by Nándor Szőcs on 23.10.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm: ScannerViewModel
    
    init() {
        // Example tags: define positions in meters (x,y). Make sure to set txPower if you know it.
        let t1 = BeaconTag(id: UUID(), name: "Tag A", macOrIdentifier: "TAG-A", xMeters: 0.5, yMeters: 0.5, txPower: -59)
        let t2 = BeaconTag(id: UUID(), name: "Tag B", macOrIdentifier: "TAG-B", xMeters: 4.0, yMeters: 0.5, txPower: -59)
        let t3 = BeaconTag(id: UUID(), name: "Tag C", macOrIdentifier: "TAG-C", xMeters: 2.25, yMeters: 3.0, txPower: -59)
        _vm = StateObject(wrappedValue: ScannerViewModel(floorWidthMeters: 5.0, floorHeightMeters: 4.0, configuredTags: [t1,t2,t3]))
    }
    
    var body: some View {
        VStack {
            Text(vm.statusMessage).padding(.top)
            FloorplanView(vm: vm, floorImage: Image("floorplan_example"))
                .frame(height: 400)
                .padding()
            
            HStack {
                Button(action: { vm.startScanning() }) { Text("Start") }
                Button(action: { vm.stopScanning() }) { Text("Stop") }
            }.padding()
            
            Form {
                Section("Tuning") {
                    Stepper("Path loss exponent n: \(String(format: "%.2f", vm.pathLossExponent))", value: $vm.pathLossExponent, in: 1.5...4.0, step: 0.1)
                    Stepper("RSSI EMA α: \(String(format: "%.2f", vm.rssiAlpha))", value: $vm.rssiAlpha, in: 0.05...0.9, step: 0.05)
                }
            }
        }
    }
}
