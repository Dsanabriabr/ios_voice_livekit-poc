//
//  CustomTab.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 08/06/26.
//

import SwiftUI

enum CustomTab: String, CaseIterable {
    case home = "Home"
    case chats = "Chat Sparky"
    case inventory = "Inventory"
    
    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .chats: return "star.bubble.fill"
        case .inventory: return "square.split.bottomrightquarter.fill"
        }
    }
    
    var actionSymbol: String {
        switch self {
        case .home: return "plus"
        case .chats: return "mic"
        case .inventory: return "barcode.viewfinder"
        }
    }
    
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
