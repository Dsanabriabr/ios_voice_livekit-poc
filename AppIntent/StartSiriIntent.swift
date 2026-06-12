//
//  StartSiriIntent.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 12/06/26.
//

import AppIntents


struct StartSiriIntent: AppIntent {

    static var title: LocalizedStringResource =
        "Talk to Spark Assistant"

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AppCoordinator.shared?.handleSiriStart()
        }
        return .result()
    }
}
