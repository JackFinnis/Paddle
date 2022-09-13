//
//  Blur.swift
//  MyMap
//
//  Created by Finnis on 14/02/2021.
//

import SwiftUI

struct Blur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
