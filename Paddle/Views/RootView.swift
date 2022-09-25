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
            CanalTitle()
                .alert("Whoops!", isPresented: $vm.tripError) {
                    Button("Cancel") {}
                    Button("Submit Manually", role: .cancel) {
                        vm.startCompleting()
                    }
                } message: {
                    Text("Sorry, we weren't able to find a canal near you. Please mark your trip as complete manually by following the steps below.")
                }
            FloatingButtons()
                .alert("Access Denied", isPresented: $vm.authError) {
                    Button("Maybe Later") {}
                    Button("Settings", role: .cancel) {
                        vm.openSettings()
                    }
                } message: {
                    Text("\(NAME) needs access to your location to show you on the map and to record a paddling trip. Please go allow access in Settings to enable these features.")
                }
        }
        .environmentObject(vm)
        .onAppear {
            vm.loadData()
        }
    }
}
