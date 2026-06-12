//
//  live.swift
//  voice_to_text
//
//  Created by Daniel Sanabria on 11/06/26.
//

let wsURL = "https://smith-xgnh0ruv.livekit.cloud"
let token = ""

import LiveKitComponents
@preconcurrency import LiveKit
import SwiftUI

struct LiveContentView: View {

    @StateObject private var session = LiveKitSessionManager()
    @EnvironmentObject var coordinator: AppCoordinator

    private var room: Room { session.room }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    connectionStatusSection
                    Spacer()
                    if session.connectionState == .disconnected {
                        Button("Connect") {
                            Task { await session.connect(url: wsURL, token: token) }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Disconnect", role: .destructive) {
                            Task { await session.disconnect() }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                participantSection
                trackSection
                eventsSection

                if session.connectionState != .disconnected {
                    LazyVStack {
                        ForEachParticipant { _ in
                            VStack {
                                ForEachTrack(filter: .video) { trackReference in
                                    VideoTrackView(trackReference: trackReference)
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task(id: coordinator.shouldStartSession) {
            guard coordinator.shouldStartSession else { return }
            guard session.connectionState == .disconnected else {
                coordinator.sessionDidStart()
                return
            }
            await session.connect(url: wsURL, token: token)
            coordinator.sessionDidStart()
        }
        .padding()
        .environmentObject(room)
    }

    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connection")
                .font(.headline)

            HStack {
                Circle()
                    .fill(connectionColor)
                    .frame(width: 10, height: 10)
                Text(connectionLabel)
                    .font(.subheadline.weight(.medium))
            }

            if let lastError = session.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var participantSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Participants")
                .font(.headline)
            Text(session.participantSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var trackSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tracks")
                .font(.headline)
            Text(session.trackSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Activity")
                .font(.headline)

            if session.events.isEmpty {
                Text("Waiting for room events…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(session.events) { event in
                    HStack(alignment: .top, spacing: 8) {
                        Text(event.source)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.teal)
                            .frame(width: 72, alignment: .leading)
                        Text(event.message)
                            .font(.caption)
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var connectionLabel: String {
        switch session.connectionState {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting…"
        case .connected: return "Connected"
        case .reconnecting: return "Reconnecting…"
        case .disconnecting: return "Disconnecting…"
        @unknown default: return "Unknown"
        }
    }

    private var connectionColor: Color {
        switch session.connectionState {
        case .connected: return .green
        case .connecting, .reconnecting: return .orange
        case .disconnecting: return .yellow
        case .disconnected: return .red
        @unknown default: return .gray
        }
    }
}
