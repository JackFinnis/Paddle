//
//  FeatureTypeRow.swift
//  Paddle
//
//  Created by Jack Finnis on 12/09/2022.
//

import SwiftUI

struct FeatureTypeRow: View {
    let type: FeatureType
    
    init(_ type: FeatureType) {
        self.type = type
    }
    
    var body: some View {
        Label {
            Text(type.name)
        } icon: {
            if type == .lock {
                Image(systemName: "chevron.right")
                    .font(.title.weight(.semibold))
                    .foregroundColor(type.color)
            } else {
                Circle()
                    .frame(width: SIZE/2, height: SIZE/2)
                    .foregroundColor(type.color)
            }
        }
    }
}
