//
//  Row.swift
//  Petition
//
//  Created by Jack Finnis on 19/08/2021.
//

import SwiftUI

struct Row<Leading: View, Trailing: View>: View {
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            leading()
            Spacer()
            trailing()
        }
    }
}
