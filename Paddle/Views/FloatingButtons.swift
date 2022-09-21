//
//  FloatingButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct FloatingButtons: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var vm: ViewModel
    @State var showInfoView = false
    
    @State var degrees = 0.0
    @State var scale = 1.0
    @State var offset = 0.0
    
    var background: Material { colorScheme == .light ? .regularMaterial : .thickMaterial }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    offset = value.translation.height
                }
            }
            .onEnded { value in
                offset = 0
                if value.predictedEndTranslation.height > 20 {
                    vm.stopMeasuring()
                    vm.stopSearching()
                }
            }
    }
    
    var body: some View {
        HStack {
            if vm.isMeasuring {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        if let distance = vm.distance {
                            HStack(spacing: 0) {
                                Text(Measurement(value: distance, unit: UnitLength.meters).formatted(.measurement(width: .wide)) + " • ")
                                    .font(.headline)
                                Menu {
                                    Picker("Speed", selection: $vm.speed) {
                                        ForEach(Speed.sorted, id: \.self) { speed in
                                            Label(speed.name, systemImage: speed.image)
                                        }
                                    }
                                } label: {
                                    Text(vm.time)
                                        .font(.headline)
                                        .animation(.none, value: vm.time)
                                }
                            }
                            
                            Text("Tap on a pin to reposition it")
                                .font(.subheadline)
                        } else {
                            Text("Measure your trip length")
                                .font(.headline)
                            Text("Tap on the start and end locations")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                    
                    if vm.distance != nil {
                        Button {
                            vm.savePolyline()
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .frame(width: SIZE, height: SIZE)
                        }
                    }
                    Divider().frame(height: 60)
                    Button {
                        vm.stopMeasuring()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: SIZE, height: SIZE)
                    }
                }
                .frame(height: 60)
                .background(background)
                .cornerRadius(10)
                .frame(maxWidth: 500)
                .transition(.move(edge: .bottom))
                .offset(x: 0, y: offset)
                .offset(x: vm.noResults ? 20 : 0, y: 0)
                .gesture(dragGesture)
                .onTapGesture {
                    if vm.distance != nil {
                        vm.zoomToPolyline()
                    }
                }
            } else if vm.isSearching {
                HStack(spacing: 0) {
                    SearchBar()
                    Button("Cancel") {
                        vm.stopSearching()
                    }
                    .font(.body)
                    .padding(.trailing, 10)
                }
                .background(background)
                .cornerRadius(10)
                .frame(maxWidth: 500)
                .transition(.move(edge: .bottom))
                .offset(x: vm.noResults ? 20 : 0, y: 0)
                .offset(x: 0, y: offset)
                .gesture(dragGesture)
            } else {
                Group {
                    HStack(spacing: 0) {
                        Button {
                            showInfoView = true
                        } label: {
                            Image(systemName: showInfoView ? "info.circle.fill" : "info.circle")
                                .frame(width: SIZE, height: SIZE)
                        }
                        .popover(isPresented: $showInfoView) {
                            InfoView()
                                .frame(idealWidth: 400, idealHeight: 700)
                                .font(nil)
                        }
                        
                        Divider().frame(height: SIZE)
                        
                        Button {
                            updateMapType()
                        } label: {
                            Image(systemName: mapTypeImage)
                                .frame(width: SIZE, height: SIZE)
                                .rotation3DEffect(.degrees(vm.mapType == .hybrid ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                                .rotation3DEffect(.degrees(degrees), axis: (x: 0, y: 1, z: 0))
                        }
                        
                        Divider().frame(height: SIZE)
                        
                        Button {
                            updateTrackingMode()
                        } label: {
                            Image(systemName: trackingModeImage)
                                .frame(width: SIZE, height: SIZE)
                                .scaleEffect(scale)
                        }
                    }
                    .background(background)
                    .cornerRadius(10)
                    
                    Spacer()
                    HStack(spacing: 0) {
                        Button {
                            vm.showFeatureView = true
                        } label: {
                            Image(systemName: "plus")
                                .frame(width: SIZE, height: SIZE)
                        }
                        .popover(isPresented: $vm.showFeatureView) {
                            EditFeatureView(editFeatureVM: EditFeatureVM(feature: vm.selectedFeature, coordinate: vm.selectedFeature?.coordinate ?? vm.coord))
                                .frame(idealWidth: 400, idealHeight: 700)
                                .font(nil)
                        }
                        
                        Divider().frame(height: SIZE)
                        
                        Button {
                            vm.isMeasuring = true
                        } label: {
                            Image(systemName: "ruler")
                                .frame(width: SIZE, height: SIZE)
                        }
                        
                        Divider().frame(height: SIZE)
                        
                        Button {
                            vm.isSearching = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .frame(width: SIZE, height: SIZE)
                        }
                    }
                    .background(background)
                    .cornerRadius(10)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .font(.system(size: SIZE/2))
        .compositingGroup()
        .shadow(color: Color(UIColor.systemFill), radius: 5)
        .padding(10)
        .animation(.default, value: vm.isSearching)
        .animation(.default, value: vm.isMeasuring)
        .onChange(of: vm.noResults) { newValue in
            if newValue {
                Haptics.error()
                withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                    vm.noResults = false
                }
            }
        }
    }
    
    func updateTrackingMode() {
        if vm.userTrackingMode == .none {
            vm.userTrackingMode = .follow
            vm.mapView?.setUserTrackingMode(vm.userTrackingMode, animated: true)
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                scale = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                switch vm.userTrackingMode {
                case .none:
                    vm.userTrackingMode = .follow
                case .follow:
                    vm.userTrackingMode = .followWithHeading
                default:
                    vm.userTrackingMode = .none
                }
                vm.mapView?.setUserTrackingMode(vm.userTrackingMode, animated: true)
                withAnimation(.easeInOut(duration: 0.3)) {
                    scale = 1
                }
            }
        }
    }
    
    func updateMapType() {
        withAnimation(.easeInOut(duration: 0.25)) {
            degrees += 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            switch vm.mapType {
            case .standard:
                vm.mapType = .hybrid
            default:
                vm.mapType = .standard
            }
            vm.mapView?.mapType = vm.mapType
            withAnimation(.easeInOut(duration: 0.3)) {
                degrees += 90
            }
        }
    }
    
    var trackingModeImage: String {
        switch vm.userTrackingMode {
        case .none: return "location"
        case .follow: return "location.fill"
        default: return "location.north.line.fill"
        }
    }
    
    var mapTypeImage: String {
        switch vm.mapType {
        case .standard: return "globe.europe.africa.fill"
        default: return "map"
        }
    }
}

struct FloatingButtons_Previews: PreviewProvider {
    static var previews: some View {
        FloatingButtons()
    }
}
