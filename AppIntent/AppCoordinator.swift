//
//  AppCoordinator.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 12/06/26.
//

import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {

    static weak var shared: AppCoordinator?

    @Published var activeTab: CustomTab = .home
    @Published var shouldStartSession = false

    init() {
        Self.shared = self
    }

    func handleSiriStart() {
        activeTab = .chats
        shouldStartSession = true
    }

    func sessionDidStart() {
        shouldStartSession = false
    }
}
