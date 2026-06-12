//
//  live.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 11/06/26.
//

let wsURL = "https://smith-xgnh0ruv.livekit.cloud"
let token = ""

@preconcurrency import LiveKit
import LiveKitComponents
import SwiftUI

struct LiveContentView: View {
    @StateObject private var room: Room

    init() {
        let room = Room()
        _room = StateObject(wrappedValue: room)
    }
    
    var body: some View {
        Group {
            if room.connectionState == .disconnected {
                Button("Connect") {
                    Task {
                        do {
                            try await room.connect(
                                url: wsURL,
                                token: token,
                                connectOptions: ConnectOptions(enableMicrophone: true)
                            )
                            try await room.localParticipant.setCamera(enabled: true)
                        } catch {
                            print("Failed to connect to LiveKit: \(error)")
                        }
                    }
                }
            } else {
                LazyVStack {
                    ForEachParticipant { _ in
                        VStack {
                            ForEachTrack(filter: .video) { trackReference in
                                VideoTrackView(trackReference: trackReference)
                                    .frame(width: 500, height: 500)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .environmentObject(room)
    }
}
