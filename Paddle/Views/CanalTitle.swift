//
//  CanalTitle.swift
//  Paddle
//
//  Created by Jack Finnis on 15/09/2022.
//

import SwiftUI

struct CanalTitle: View {
    @EnvironmentObject var vm: ViewModel
    
    var totalDistance: Double {
        Double(vm.selectedCanals.reduce(0) { $0 + $1.distance })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if vm.selectedCanalId == nil {
                Blur()
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                VStack(spacing: 5) {
                    Text(vm.selectedCanals.first?.name ?? "")
                        .font(.headline)
                    DistanceLabel(distance: totalDistance)
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
