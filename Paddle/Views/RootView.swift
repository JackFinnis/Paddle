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
            FloatingButtons()
        }
        .environmentObject(vm)
        .onAppear {
            vm.loadData()
        }
    }
}
