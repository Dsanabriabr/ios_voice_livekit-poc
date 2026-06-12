//
//  AppCoordinator.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 12/06/26.
//

import Combine

@MainActor
final class AppCoordinator: ObservableObject {

    @Published var shouldStartSession = false

    func startSession() {
        shouldStartSession = true
    }
}
