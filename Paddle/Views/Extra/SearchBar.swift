//
//  SearchBar.swift
//  Paddle
//
//  Created by Jack Finnis on 14/09/2022.
//

import SwiftUI

struct SearchBar: UIViewRepresentable {
    @EnvironmentObject var vm: ViewModel
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = vm
        vm.searchBar = searchBar
        
        searchBar.placeholder = "Canals, Features, Locations"
        searchBar.backgroundImage = UIImage()
        searchBar.autocorrectionType = .no
        searchBar.textContentType = .location
        searchBar.becomeFirstResponder()
        
        return searchBar
    }
    
    func updateUIView(_ searchBar: UISearchBar, context: Context) {}
}
