//
//  DistanceLabel.swift
//  Paddle
//
//  Created by Jack Finnis on 24/09/2022.
//

import SwiftUI

struct DistanceButton: View {
    @EnvironmentObject var vm: ViewModel
    
    let distance: Double
    
    var body: some View {
        Menu {
            Picker("Unit Distance", selection: $vm.metric) {
                Text("Miles")
                    .tag(false)
                Text("Kilometers")
                    .tag(true)
            }
        } label: {
            DistanceLabel(distance: distance)
                .frame(width: 100)
        }
    }
}

struct DistanceLabel: View {
    @EnvironmentObject var vm: ViewModel
    
    let distance: Double
    
    var formattedDistance: String {
        let distance = Measurement(value: distance, unit: UnitLength.meters).converted(to: vm.metric ? .kilometers : .miles)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: distance)
    }
    
    var body: some View {
        Text(formattedDistance)
            .animation(.none)
    }
}
