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
    @EnvironmentObject var coordinator: AppCoordinator
    
    init() {
        let room = Room()
        _room = StateObject(wrappedValue: room)
    }
    
    func connectToLiveKit() async {

        do {

            try await room.connect(
                url: wsURL,
                token: token,
                connectOptions: ConnectOptions(
                    enableMicrophone: true
                )
            )

            try await room.localParticipant
                .setMicrophone(enabled: true)

        } catch {

            print(error)
        }
    }
    
    var body: some View {
        Group {
            if room.connectionState == .disconnected {
                Button("Connect") {
                    Task {
                        await connectToLiveKit()
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
        }.onChange(of: coordinator.shouldStartSession) { _, shouldStart in
            
            guard shouldStart else { return }

            Task {

                await connectToLiveKit()

            }

        }
        .padding()
        .environmentObject(room)
    }
}
