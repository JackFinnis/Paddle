//
//  RootView.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct RootView: View {
    @StateObject var vm = ViewModel()

    var body: some View {
        ZStack {
            MapView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if vm.selectedCanalName?.isNotEmpty ?? false {
                    Text(vm.selectedCanalName ?? "").font(.headline)
                        .animation(.none, value: vm.selectedCanalName)
                        .padding(.bottom, 10)
                        .horizontallyCentred()
                        .onTapGesture(perform: vm.setSelectedRegion)
                        .background {
                            Blur().ignoresSafeArea()
                        }
                } else {
                    Blur().ignoresSafeArea()
                }
                
                Divider()
                Spacer()
                    .layoutPriority(1)
            }
            .animation(.default, value: vm.selectedCanalName)
            
            VStack {
                Spacer()
                FloatingButtons()
            }
        }
        .preferredColorScheme(vm.mapType == .hybrid ? .dark : .light)
        .environmentObject(vm)
        .onAppear {
            vm.loadData()
        }
    }
}
