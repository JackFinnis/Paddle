//
//  InfoView.swift
//  Rivers
//
//  Created by Jack Finnis on 24/06/2022.
//

import SwiftUI
import StoreKit

struct InfoView: View {
    @Environment(\.dismiss) var dismiss
    @State var showShareSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {} header: {
                    Text("About Us")
                }
                
                Section {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share UK Waterways", systemImage: "square.and.arrow.up")
                    }
                    .sheet(isPresented: $showShareSheet) {
                        ShareView()
                    }
                    
                    Button {
                        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    } label: {
                        Label("Rate UK Waterways", systemImage: "star")
                    }
                    
                    Button {
                        var components = URLComponents(url: APP_URL, resolvingAgainstBaseURL: false)
                        components?.queryItems = [
                            URLQueryItem(name: "action", value: "write-review")
                        ]
                        if let url = components?.url {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Write a Review", systemImage: "quote.bubble")
                    }
                    
                    Button {
                        let url = URL(string: "mailto:" + EMAIL + "?subject=UK%20Waterways%20Feedback")!
                        UIApplication.shared.open(url)
                    } label: {
                        Label("Send Us Feedback", systemImage: "envelope")
                    }
                } header: {
                    Text("Contribute")
                }
                
                Section {} header: {
                    Text("Acknowledgements")
                } footer: {
                    Text("With thanks to the Canal & River Trust and Open Canal Map UK for providing canal features.")
                }
            }
            .navigationTitle(NAME)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done").bold()
                    }
                }
            }
        }
    }
}
