//
//  CustomTab.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 08/06/26.
//

enum CustomTab: String, CaseIterable {
    case home = "Home"
    case chats = "Chats"
    case inventory = "Inventory"
    
    var symbol: String {
        switch self {
        case .home: return "house"
        case .chats: return "chat"
        case .inventory: return "board"
        }
    }
    
    var actionSymbol: String {
        switch self {
        case .home: return "house"
        case .chats: return "chat"
        case .inventory: return "board"
        }
    }
    
    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
