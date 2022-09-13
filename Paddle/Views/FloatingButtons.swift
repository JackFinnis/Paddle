//
//  FloatingButtons.swift
//  Paddle
//
//  Created by Jack Finnis on 11/09/2022.
//

import SwiftUI

struct FloatingButtons: View {
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        HStack(spacing: 20) {
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
            .background(Blur())
            .cornerRadius(10)
            .font(.system(size: SIZE/2))
            .compositingGroup()
            
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
                    //todo
                } label: {
                    Image(systemName: "record.circle")
                        .frame(width: SIZE, height: SIZE)
                }
                
                Divider().frame(height: SIZE)
                
                Button {
                    //todo
                } label: {
                    Image(systemName: "magnifyingglass")
                        .frame(width: SIZE, height: SIZE)
                }
            }
            .background(Blur())
            .cornerRadius(10)
            .font(.system(size: SIZE/2))
            .compositingGroup()
        }
        .shadow(color: Color(UIColor.systemFill), radius: 5)
        .padding(10)
        .frame(maxWidth: 500)
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
