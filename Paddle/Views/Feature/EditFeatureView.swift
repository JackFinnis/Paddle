//
//  FeatureView.swift
//  Rivers
//
//  Created by Jack Finnis on 31/05/2022.
//

import SwiftUI
import CoreLocation

struct EditFeatureView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var vm: ViewModel
    @State var showConfirmation = false
    
    @StateObject var editFeatureVM: EditFeatureVM
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollView in
                Form {
                    Section {
                        TextField("Name", text: $editFeatureVM.name)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                        Picker("Type", selection: $editFeatureVM.type) {
                            ForEach(FeatureType.allCases, id: \.self) { type in
                                FeatureTypeRow(type)
                            }
                        }
                        if editFeatureVM.type == .lock {
                            HStack {
                                Text("Direction")
                                Slider(value: $editFeatureVM.angle, in: -360...360)
                            }
                        }
                    } header: {
                        ZStack {
                            MapBox(editFeatureVM: editFeatureVM)
                            if editFeatureVM.type == .lock {
                                Image(systemName: "chevron.left")
                                    .font(.title.weight(.semibold))
                                    .rotationEffect(.degrees(editFeatureVM.angle))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .frame(width: SIZE/2, height: SIZE/2)
                                    .foregroundColor(editFeatureVM.type.color)
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
            .navigationTitle(editFeatureVM.feature == nil ? "New Feature" : "Edit Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    if let feature = editFeatureVM.feature {
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
        .navigationViewStyle(.stack)
    }
    
    func submit() {
        let feature: Feature
        if let existingFeature = editFeatureVM.feature {
            feature = existingFeature
        } else {
            feature = Feature(context: vm.container.viewContext)
            feature.id = UUID().uuidString
        }
        feature.lat = editFeatureVM.coord.latitude
        feature.long = editFeatureVM.coord.longitude
        feature.name = editFeatureVM.name
        feature.type = editFeatureVM.type
        if feature.type == .lock {
            feature.angle = editFeatureVM.angle
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
