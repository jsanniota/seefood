//
//  ContentView.swift
//  seefood
//
//  Created by Jack Sanniota on 1/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            CameraView()
                .navigationTitle("SeeFood")
        }
    }
}

#Preview {
    ContentView()
}
