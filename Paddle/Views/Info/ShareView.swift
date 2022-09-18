//
//  ShareView.swift
//  Rivers
//
//  Created by Jack Finnis on 25/06/2022.
//

import SwiftUI

struct ShareView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [APP_URL], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
