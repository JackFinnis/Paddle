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
    
    var background: Material { colorScheme == .light ? .regularMaterial : .thickMaterial }
    
    var body: some View {
        HStack {
            if vm.isSearching {
                HStack(spacing: 0) {
                    SearchBar()
                    Button("Cancel") {
                        vm.isSearching = false
                    }
                    .font(.body)
                    .padding(.trailing, 10)
                }
                .background(background)
                .cornerRadius(10)
                .transition(.move(edge: .bottom))
                .offset(x: vm.noResults ? 20 : 0, y: 0)
                .onChange(of: vm.noResults) { newValue in
                    if newValue {
                        withAnimation(Animation.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                            vm.noResults = false
                        }
                    }
                }
            } else {
                Group {
                    HStack(spacing: 0) {
                        Button {
                            updateMapType()
                        } label: {
                            Image(systemName: mapTypeImage)
                                .frame(width: SIZE, height: SIZE)
                        }
                        
                        Divider().frame(height: SIZE)
                        
                        Button {
                            updateTrackingMode()
                        } label: {
                            Image(systemName: trackingModeImage)
                                .frame(width: SIZE, height: SIZE)
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
                            FeatureView(featureVM: FeatureVM(feature: vm.selectedFeature, coordinate: vm.selectedFeature?.coordinate ?? vm.coord))
                                .font(nil)
                        }
                        
                        Divider().frame(height: SIZE)
                        
                        Button {
                            //todo
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
    }
    
    func updateTrackingMode() {
        switch vm.userTrackingMode {
        case .none:
            vm.userTrackingMode = .follow
        case .follow:
            vm.userTrackingMode = .followWithHeading
        default:
            vm.userTrackingMode = .none
        }
        vm.mapView?.setUserTrackingMode(vm.userTrackingMode, animated: true)
    }
    
    func updateMapType() {
        switch vm.mapType {
        case .standard:
            vm.mapType = .hybrid
        default:
            vm.mapType = .standard
        }
        vm.mapView?.mapType = vm.mapType
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
