//
//  ContentView.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 08/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var activeTab: CustomTab = .home
    @State private var isTabA: Bool = true
    var body: some View {
        TabView(selection: $activeTab) {
            Tab.init(value: .home) {
                Text("Home")
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab.init(value: .chats) {
                Text("Chats")
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            Tab.init(value: .inventory) {
                Text("Inventory")
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBarView()
                .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    func CustomTabBarView() -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                GeometryReader {
                    if isTabA {
                        CustomTabBar(size: $0.size, activeTab: $activeTab) {
                            tab in
                            VStack(spacing: 3) {
                                Image(systemName: tab.symbol)
                                    .font(.title3)
                                Text(tab.rawValue)
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                            }
                            .symbolVariant(.fill)
                            .frame(maxWidth: .infinity)
                        }
                        .glassEffect(.regular.interactive(), in: .capsule)
                    } else {
                        CustomTabBar2(size: $0.size, activeTab: $activeTab)
                            .overlay {
                                HStack(spacing: 0) {
                                    ForEach(CustomTab.allCases, id: \.rawValue) { tab in
                                        VStack(spacing: 3) {
                                            Image(systemName: tab.symbol)
                                                .font(.title3)
                                            Text(tab.rawValue)
                                                .font(.system(size: 10))
                                                .fontWeight(.medium)
                                        }
                                        .symbolVariant(.fill)
                                        .foregroundStyle(activeTab == tab ? .teal : .primary)
                                        .frame(maxWidth: .infinity)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.25), value: activeTab)
                            }
                            .glassEffect(.regular.interactive(), in: .capsule)
                    }
                }
                
                ZStack {
                    ForEach(CustomTab.allCases, id: \.rawValue) {
                        tab in
                        Image(systemName: tab.actionSymbol)
                            .font(.system(size: 22, weight: .medium))
                            .blurFade(activeTab == tab)
                    }
                }
                .frame(width: 55, height: 55)
                .glassEffect(.regular.interactive(), in: .capsule)
                .animation(.smooth(duration: 0.55, extraBounce: 0), value: activeTab)
            }
        }
        .frame(height: 55)
    }
}

extension View {
    @ViewBuilder
    func blurFade(_ status: Bool) -> some View {
        self
            .compositingGroup()
            .blur(radius: status ? 0 : 10)
            .opacity(status ? 1 : 0)
    }
}

#Preview {
    ContentView()
}
