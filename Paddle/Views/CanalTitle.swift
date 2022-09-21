//
//  CanalTitle.swift
//  Paddle
//
//  Created by Jack Finnis on 15/09/2022.
//

import SwiftUI

struct CanalTitle: View {
    @EnvironmentObject var vm: ViewModel
    
    var formattedDistance: String {
        let totalDistance = vm.selectedCanals.reduce(0) { $0 + $1.distance }
        let measurement = Measurement(value: Double(totalDistance), unit: UnitLength.meters)
        return measurement.formatted(.measurement(width: .wide))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if vm.selectedCanalId == nil {
                Blur()
                    .ignoresSafeArea()
//                    .transition(.opacity)
            } else {
                VStack {
                    Text(vm.selectedCanals.first?.name ?? "")
                        .font(.headline)
                    Text(formattedDistance)
                        .font(.subheadline)
                }
                .animation(.none, value: vm.selectedCanalId)
                .frame(height: 50)
                .horizontallyCentred()
                .background(Blur().ignoresSafeArea())
                .onTapGesture(perform: vm.setSelectedRegion)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Spacer()
                .layoutPriority(1)
        }
        .animation(.default, value: vm.selectedCanalId)
    }
}
