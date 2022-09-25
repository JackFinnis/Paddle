//
//  CanalTitle.swift
//  Paddle
//
//  Created by Jack Finnis on 15/09/2022.
//

import SwiftUI

struct CanalTitle: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vm: ViewModel
    @State var showStopConfimation = false
    
    var totalDistance: Double {
        Double(vm.selectedCanals.reduce(0) { $0 + $1.distance })
    }
    
    var background: Material { colorScheme == .light ? .regularMaterial : .thickMaterial }
    
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
                        .font(.subheadline.bold())
                }
                .animation(.none, value: vm.selectedCanalId)
                .frame(height: 50)
                .horizontallyCentred()
                .background(Blur().ignoresSafeArea())
                .onTapGesture(perform: vm.setSelectedRegion)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            if vm.isPaddling {
                HStack(spacing: 0) {
                    DistanceLabel(distance: vm.tripDistance)
                        .padding(.leading)
                    Text(" • ")
                    Text(vm.startedPaddling, style: .timer)
                    Spacer()
                    
                    Divider().frame(height: SIZE)
                    Button {
                        showStopConfimation = true
                    } label: {
                        Image(systemName: "stop.fill")
                            .frame(width: SIZE, height: SIZE)
                            .font(.system(size: SIZE/2))
                            .foregroundColor(.red)
                    }
                    .confirmationDialog("Finish Trip?", isPresented: $showStopConfimation, titleVisibility: .visible) {
                        Button("Cancel", role: .cancel) {}
                        Button("Finish", role: .destructive) {
                            vm.stopPaddling()
                        }
                    }
                }
                .frame(height: SIZE)
                .font(.headline)
                .background(background)
                .cornerRadius(10)
                .frame(maxWidth: 500)
                .transition(.move(edge: .top))
                .compositingGroup()
                .shadow(color: Color(UIColor.systemFill), radius: 5)
                .padding(10)
            }
            
            Spacer()
                .layoutPriority(1)
        }
        .animation(.default, value: vm.selectedCanalId)
        .animation(.default, value: vm.isPaddling)
    }
}
