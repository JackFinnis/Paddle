//
//  FeatureView.swift
//  Rivers
//
//  Created by Jack Finnis on 31/05/2022.
//

import SwiftUI
import CoreLocation

struct FeatureView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: ViewModel
    @State var showConfirmation = false
    
    @StateObject var featureVM: FeatureVM
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollView in
                Form {
                    Section {
                        TextField("Name", text: $featureVM.name)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                        Picker("Type", selection: $featureVM.type) {
                            ForEach(FeatureType.allCases, id: \.self) { type in
                                FeatureTypeRow(type)
                            }
                        }
                        if featureVM.type == .lock {
                            HStack {
                                Text("Direction")
                                Slider(value: $featureVM.angle, in: -360...360)
                            }
                        }
                    } header: {
                        ZStack {
                            MapBox(featureVM: featureVM)
                            if featureVM.type == .lock {
                                Image(systemName: "chevron.left")
                                    .font(.title.weight(.semibold))
                                    .rotationEffect(.degrees(featureVM.angle))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .frame(width: SIZE/2, height: SIZE/2)
                                    .foregroundColor(featureVM.type.color)
                            }
                        }
                        .aspectRatio(1, contentMode: .fill)
                        .cornerRadius(10)
                    }
                    
                    Button("Submit", action: submit)
                        .horizontallyCentred()
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .listRowBackground(Color.accentColor)
                }
            }
            .navigationTitle(featureVM.feature == nil ? "New Feature" : "Edit Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    if let feature = featureVM.feature {
                        Button("Delete", role: .destructive) {
                            showConfirmation = true
                        }
                        .foregroundColor(.red)
                        .confirmationDialog("Delete Feature?", isPresented: $showConfirmation, titleVisibility: .hidden) {
                            Button("Cancel", role: .cancel) {}
                            Button("Delete", role: .destructive) {
                                delete(feature: feature)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func submit() {
        let feature: Feature
        if let existingFeature = featureVM.feature {
            feature = existingFeature
        } else {
            feature = Feature(context: vm.container.viewContext)
            feature.id = UUID().uuidString
        }
        feature.coord = [featureVM.coord.latitude, featureVM.coord.longitude]
        feature.name = featureVM.name
        feature.type = featureVM.type
        if feature.type == .lock {
            feature.angle = featureVM.angle
        }
        vm.save()
        
        vm.mapView?.removeAnnotation(feature)
        vm.mapView?.addAnnotation(feature)
        
        if let index = vm.features.firstIndex(of: feature) {
            vm.features.remove(at: index)
        }
        vm.features.append(feature)
        
        Haptics.success()
        dismiss()
    }
    
    func delete(feature: Feature) {
        if let index = vm.features.firstIndex(of: feature) {
            vm.features.remove(at: index)
        }
        vm.mapView?.removeAnnotation(feature)
        
        vm.container.viewContext.delete(feature)
        vm.save()
        
        Haptics.success()
        dismiss()
    }
}
