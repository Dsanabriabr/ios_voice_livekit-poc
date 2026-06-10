//
//  CustomTabBar3.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 10/06/26.
//

import SwiftUI

struct CurvedTabBar: View {
    @Binding var selectedTab: CustomTab
    let onCenterTap: () -> Void
 
    var body: some View {
        ZStack {
            // Background
            CurvedShape()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
 
            // Tab items
            HStack {
                TabBarItem(icon: "house.fill", isSelected: selectedTab.index == 0) {
                    selectedTab = CustomTab.allCases[0]
                }
 
                TabBarItem(icon: "magnifyingglass", isSelected: selectedTab.index == 1) {
                    selectedTab = CustomTab.allCases[1]
                }
 
                Spacer()
                    .frame(width: 60)
 
                TabBarItem(icon: "heart.fill", isSelected: selectedTab.index == 2) {
                    selectedTab = CustomTab.allCases[2]
                }
 
                TabBarItem(icon: "person.fill", isSelected: selectedTab.index == 3) {
                    selectedTab = CustomTab.allCases[2]
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 15)
 
            // Center button
            Button(action: onCenterTap) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: .blue.opacity(0.4), radius: 10, y: 5)
            }
            .offset(y: -30)
        }
        .frame(height: 80)
    }
}
 
struct CurvedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
 
        let curveHeight: CGFloat = 35
        let curveWidth: CGFloat = 80
        let centerX = rect.midX
 
        path.move(to: CGPoint(x: 0, y: curveHeight))
        path.addLine(to: CGPoint(x: centerX - curveWidth, y: curveHeight))
 
        // Curve
        path.addQuadCurve(
            to: CGPoint(x: centerX + curveWidth, y: curveHeight),
            control: CGPoint(x: centerX, y: -curveHeight)
        )
 
        path.addLine(to: CGPoint(x: rect.width, y: curveHeight))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
 
        return path
    }
}
 
struct TabBarItem: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
 
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .blue : .gray)
                .frame(maxWidth: .infinity)
        }
    }
}
