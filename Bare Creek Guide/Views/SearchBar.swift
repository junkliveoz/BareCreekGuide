//
//  SearchBar.swift
//  Bare Creek Guide
//
//  Created on 11/3/2025.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    // For preview purposes
    @State var searchText = "Liv"
    
    return SearchBar(text: $searchText, placeholder: "Search trails")
        .previewLayout(.sizeThatFits)
        .padding()
}
