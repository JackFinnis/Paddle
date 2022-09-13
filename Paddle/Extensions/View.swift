//
//  View.swift
//  Ecommunity
//
//  Created by Jack Finnis on 16/01/2022.
//

import SwiftUI

extension View {
    func horizontallyCentred() -> some View {
        HStack {
            Spacer()
            self
            Spacer()
        }
    }
}
