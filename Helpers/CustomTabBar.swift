//
//  CustomTabBar.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 08/06/26.
//

import SwiftUI

struct CustomTabBar<TabItemView: View> : UIViewRepresentable {
    var size: CGSize
    var activeTint: Color = .teal
    var inactiveTint: Color = .gray.opacity(0.95)
    var barTint: Color = .gray.opacity(0.15)
    @Binding var activeTab:CustomTab
    @ViewBuilder var tabItemView: (CustomTab) -> TabItemView
    
    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UISegmentedControl {
        let items = CustomTab.allCases.map(\.rawValue)
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        
        for (index, tab) in CustomTab.allCases.enumerated() {
            let renderer = ImageRenderer(content: tabItemView(tab))
            renderer.scale = 2
            let image = renderer.uiImage
            control.setImage(image, forSegmentAt: index)
        }
        
        DispatchQueue.main.async {
            for subview in control.subviews {
                if subview is UIImageView && subview != control.subviews.last {
                    subview.alpha = 0
                }
            }
        }
        control.selectedSegmentTintColor = UIColor(barTint)
        control.setTitleTextAttributes([.foregroundColor: UIColor(activeTint)], for: .selected)
        control.setTitleTextAttributes([.foregroundColor: UIColor(inactiveTint)], for: .normal)
        control.addTarget(context.coordinator, action: #selector(context.coordinator.tabSelected(_:)), for: .valueChanged)
        return control
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISegmentedControl, context: Context) -> CGSize? {
        return size
    }
    
    class Coordinator: NSObject {
        var parent: CustomTabBar
        init(parent: CustomTabBar) {
            self.parent = parent
        }
        
        @objc func tabSelected(_ control: UISegmentedControl) {
            parent.activeTab = CustomTab.allCases[control.selectedSegmentIndex]
        }
    }
    
}

#Preview {
    ContentView()
}
