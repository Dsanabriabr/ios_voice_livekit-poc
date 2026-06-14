//
//  AppCoordinator.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 14/06/26.
//

import Combine

@MainActor
final class AppCoordinator: ObservableObject {

    static weak var shared: AppCoordinator?

    @Published var shouldStartSession = false

    init() {
        Self.shared = self
    }

    func handleSiriStart() {
        shouldStartSession = true
    }

    func sessionDidStart() {
        shouldStartSession = false
    }
}
