//
//  InfoView.swift
//  Rivers
//
//  Created by Jack Finnis on 24/06/2022.
//

import SwiftUI

struct InfoView: View {
    @EnvironmentObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    @State var showShareSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button {
                        vm.requestReview()
                    } label: {
                        Label("Rate \(NAME)", systemImage: "star")
                    }
                    
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share \(NAME)", systemImage: "square.and.arrow.up")
                    }
                    .sheet(isPresented: $showShareSheet) {
                        ShareView()
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
                        Label("Write a review", systemImage: "quote.bubble")
                    }
                    
                    Button {
                        let url = URL(string: "mailto:" + EMAIL + "?subject=\(NAME)%20Feedback")!
                        UIApplication.shared.open(url)
                    } label: {
                        Label("Send us feedback", systemImage: "envelope")
                    }
                } header: {
                    VStack {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .cornerRadius(25)
                        Text(NAME)
                            .font(.title3.bold())
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                        
                        Text("\(NAME) gives you everything you need to plan your next paddling adventure. Please consider rating the app and sharing it with your friends.")
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                }
                .headerProminence(.increased)
                
                Section {} header: {
                    Text("Acknowledgements")
                } footer: {
                    Text("With thanks to the Canal & River Trust and Open Canal Map UK for providing canal features.\n\n© The Canal & River Trust copyright and database rights reserved 2022.")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .bold()
                    }
                }
            }
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}
