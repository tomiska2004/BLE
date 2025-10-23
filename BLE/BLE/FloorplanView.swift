//
//  FloorplanView.swift
//  BLE
//
//  Created by Nándor Szőcs on 23.10.2025.
//


// FloorplanView.swift (SwiftUI)
import SwiftUI

struct FloorplanView: View {
    @ObservedObject var vm: ScannerViewModel
    let floorImage: Image
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                floorImage
                    .resizable()
                    .scaledToFit()
                    .onAppear {
                        vm.viewWidthPixels = geo.size.width
                        vm.viewHeightPixels = geo.size.height
                    }
                
                // Tags on floorplan
                ForEach(vm.tags) { tag in
                    let px = vm.mapXMetersToPixel(xMeters: tag.xMeters)
                    let py = vm.mapYMetersToPixel(yMeters: tag.yMeters)
                    VStack(spacing: 2) {
                        Circle()
                            .strokeBorder(lineWidth: 2)
                            .frame(width: 18, height: 18)
                        Text(tag.name)
                            .font(.caption2)
                    }
                    .position(x: px, y: py)
                }
                
                // User position
                if let pos = vm.userPosition {
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 20, height: 20)
                        .position(pos)
                        .shadow(radius: 3)
                }
            }
        }
    }
}
