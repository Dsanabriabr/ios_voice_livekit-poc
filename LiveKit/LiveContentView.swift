//
//  live.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 11/06/26.
//

let wsURL = "https://smith-xgnh0ruv.livekit.cloud"
let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJBUElRRTUyejRWVGhDWVYiLCJzdWIiOiJ0ZXN0IGlvcyIsImV4cCI6MTc4MTI4MjQxNywibmJmIjoxNzgxMjgxNTE3LCJpYXQiOjE3ODEyODE1MTcsImlkZW50aXR5IjoidGVzdCBpb3MiLCJ2aWRlbyI6eyJyb29tSm9pbiI6dHJ1ZSwicm9vbSI6InRlc3QiLCJjYW5QdWJsaXNoIjp0cnVlLCJjYW5TdWJzY3JpYmUiOnRydWUsImNhblB1Ymxpc2hEYXRhIjp0cnVlfX0.0pGfo0WOpIXwxk1IQXN1ld2ZkFyvweIO81_rGLHQleE"


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
        }
        .task(id: coordinator.shouldStartSession) {
            guard coordinator.shouldStartSession else { return }
            guard room.connectionState == .disconnected else {
                coordinator.sessionDidStart()
                return
            }
            await connectToLiveKit()
            coordinator.sessionDidStart()
        }
        .padding()
        .environmentObject(room)
    }
}
