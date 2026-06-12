//
//  AppShortcut.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 12/06/26.
//

import AppIntents

struct AppShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        
            AppShortcut(
                intent: StartSiriIntent(),
                phrases: [
                    "Talk to \(.applicationName) Assistant",
                    "Open \(.applicationName) assistant",
                    "Call \(.applicationName) assistant",
                    "Start \(.applicationName) help"
                ],
                shortTitle: "Spark AI",
                systemImageName: "person.wave.2"
            )
        
    }
}
