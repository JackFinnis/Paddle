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
                    Text(vm.selectedCanalName ?? "")
                        .font(.headline)
                        .animation(.none, value: vm.selectedCanalName)
                        .frame(height: 50)
                        .horizontallyCentred()
                        .background(Blur().ignoresSafeArea())
                        .onTapGesture(perform: vm.setSelectedRegion)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    Blur()
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                
                Spacer()
                    .layoutPriority(1)
            }
            .animation(.default, value: vm.selectedCanalName)
            
            VStack {
                Spacer()
                FloatingButtons()
            }
        }
        .environmentObject(vm)
        .onAppear {
            vm.loadData()
        }
    }
}
