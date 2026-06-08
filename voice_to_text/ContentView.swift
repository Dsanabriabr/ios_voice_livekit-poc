//
//  ContentView.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 08/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var activeTab: CustomTab = .home
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                GeometryReader {
                    CustomTabBar(size: $0.size, activeTab: $activeTab) {
                        tab in
                        
                    }
                }
            }
            .frame(height: 55)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    ContentView()
}
