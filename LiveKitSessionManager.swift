//
//  LiveKitSessionManager.swift
//  voice_to_text
//

@preconcurrency import LiveKit
import Combine
import SwiftUI

public  struct SessionEvent: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let source: String
    public let message: String
}

let wsURL = "https://smith-xgnh0ruv.livekit.cloud"
let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJBUElRRTUyejRWVGhDWVYiLCJzdWIiOiJpb3MgYXBwIiwiZXhwIjoxNzgxNDQ2MDEwLCJuYmYiOjE3ODE0NDUxMTAsImlhdCI6MTc4MTQ0NTExMCwiaWRlbnRpdHkiOiJpb3MgYXBwIiwidmlkZW8iOnsicm9vbUpvaW4iOnRydWUsInJvb20iOiJ0ZXN0IiwiY2FuUHVibGlzaCI6dHJ1ZSwiY2FuU3Vic2NyaWJlIjp0cnVlLCJjYW5QdWJsaXNoRGF0YSI6dHJ1ZX19.Au4s5ZqxNfUuTptVk_pL8wGcHbHjbV0496a3fBbYpEw"

@MainActor
public final class LiveKitSessionManager: NSObject, ObservableObject {

    public let room: Room

    @Published private(set) public var connectionState: ConnectionState = .disconnected
    @Published private(set) public var events: [SessionEvent] = []
    @Published private(set) public var participantSummary = "No participants"
    @Published private(set) public var trackSummary = "No tracks"
    @Published private(set) public var lastError: String?

    private let maxEvents = 50

    public override init() {
        room = Room()
        super.init()
        room.add(delegate: self)
    }

    public func connect() async {
        lastError = nil
        log("Room", "Connecting…")

        do {
            try await room.connect(
                url: wsURL,
                token: token,
                connectOptions: ConnectOptions(enableMicrophone: true)
            )
            try await room.localParticipant.setMicrophone(enabled: true)
        } catch {
            lastError = error.localizedDescription
            log("Room", "Connect failed: \(error.localizedDescription)")
        }
    }

    public func disconnect() async {
        log("Room", "Disconnecting…")
        await room.disconnect()
    }

    private func registerParticipants() {
        room.localParticipant.add(delegate: self)
        for participant in room.remoteParticipants.values {
            participant.add(delegate: self)
        }
        refreshParticipantSummary()
    }

    private func registerTrackDelegate(for publication: TrackPublication) {
        publication.track?.add(delegate: self)
        refreshTrackSummary()
    }

    private func refreshParticipantSummary() {
        let local = room.localParticipant.identity?.stringValue ?? "local"
        let remoteNames = room.remoteParticipants.values.map {
            $0.identity?.stringValue ?? $0.name ?? "remote"
        }
        if remoteNames.isEmpty {
            participantSummary = "Local: \(local)"
        } else {
            participantSummary = "Local: \(local) · Remote: \(remoteNames.joined(separator: ", "))"
        }
    }

    private func refreshTrackSummary() {
        var lines: [String] = []

        for publication in room.localParticipant.trackPublications.values {
            let kind = publication.kind == .audio ? "audio" : "video"
            let state = publication.track == nil ? "pending" : "live"
            lines.append("Local \(kind) (\(state))")
        }

        for participant in room.remoteParticipants.values {
            let name = participant.identity?.stringValue ?? "remote"
            for publication in participant.trackPublications.values {
                let kind = publication.kind == .audio ? "audio" : "video"
                let state = publication.track == nil ? "pending" : "live"
                lines.append("\(name) \(kind) (\(state))")
            }
        }

        trackSummary = lines.isEmpty ? "No tracks" : lines.joined(separator: " · ")
    }

    private func log(_ source: String, _ message: String) {
        events.insert(SessionEvent(timestamp: .now, source: source, message: message), at: 0)
        if events.count > maxEvents {
            events.removeLast(events.count - maxEvents)
        }
    }

    nonisolated private func logOnMain(_ source: String, _ message: String) {
        Task { @MainActor in
            self.log(source, message)
        }
    }
}

// MARK: - RoomDelegate

extension LiveKitSessionManager: RoomDelegate {

    nonisolated public func room(
        _ room: Room,
        didUpdateConnectionState connectionState: ConnectionState,
        from oldConnectionState: ConnectionState
    ) {
        Task { @MainActor in
            self.connectionState = connectionState
            self.log("Room", "State: \(oldConnectionState) → \(connectionState)")
        }
    }

    nonisolated public func roomDidConnect(_ room: Room) {
        Task { @MainActor in
            self.connectionState = room.connectionState
            self.registerParticipants()
            self.log("Room", "Connected to \(room.name ?? "room")")
        }
    }

    nonisolated public func roomIsReconnecting(_ room: Room) {
        logOnMain("Room", "Reconnecting…")
    }

    nonisolated public func roomDidReconnect(_ room: Room) {
        logOnMain("Room", "Reconnected")
    }

    nonisolated public func room(_ room: Room, didFailToConnectWithError error: LiveKitError?) {
        Task { @MainActor in
            let message = error?.localizedDescription ?? "Unknown error"
            self.lastError = message
            self.log("Room", "Failed to connect: \(message)")
        }
    }

    nonisolated public func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        Task { @MainActor in
            self.connectionState = room.connectionState
            if let error {
                self.lastError = error.localizedDescription
                self.log("Room", "Disconnected with error: \(error.localizedDescription)")
            } else {
                self.log("Room", "Disconnected")
            }
            self.refreshParticipantSummary()
            self.refreshTrackSummary()
        }
    }

    nonisolated public func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        Task { @MainActor in
            participant.add(delegate: self)
            self.refreshParticipantSummary()
            let name = participant.identity?.stringValue ?? participant.name ?? "remote"
            self.log("Participant", "\(name) joined")
        }
    }

    nonisolated public func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        Task { @MainActor in
            self.refreshParticipantSummary()
            self.refreshTrackSummary()
            let name = participant.identity?.stringValue ?? participant.name ?? "remote"
            self.log("Participant", "\(name) left")
        }
    }

    nonisolated public func room(
        _ room: Room,
        participant: LocalParticipant,
        didPublishTrack publication: LocalTrackPublication
    ) {
        Task { @MainActor in
            self.registerTrackDelegate(for: publication)
            self.log("Track", "Published local \(publication.kind)")
        }
    }

    nonisolated public func room(
        _ room: Room,
        participant: RemoteParticipant,
        didPublishTrack publication: RemoteTrackPublication
    ) {
        Task { @MainActor in
            self.refreshTrackSummary()
            let name = participant.identity?.stringValue ?? "remote"
            self.log("Track", "\(name) published \(publication.kind)")
        }
    }

    nonisolated public func room(
        _ room: Room,
        participant: RemoteParticipant,
        didSubscribeTrack publication: RemoteTrackPublication
    ) {
        Task { @MainActor in
            self.registerTrackDelegate(for: publication)
            let name = participant.identity?.stringValue ?? "remote"
            self.log("Track", "Subscribed to \(name) \(publication.kind)")
        }
    }
}

// MARK: - ParticipantDelegate

extension LiveKitSessionManager: ParticipantDelegate {

    nonisolated public func participant(_ participant: Participant, didUpdateIsSpeaking isSpeaking: Bool) {
        Task { @MainActor in
            let name = participant.identity?.stringValue ?? participant.name ?? "participant"
            self.log("Participant", "\(name) speaking: \(isSpeaking)")
        }
    }

    nonisolated public func participant(_ participant: Participant, didUpdateState state: ParticipantState) {
        Task { @MainActor in
            let name = participant.identity?.stringValue ?? participant.name ?? "participant"
            self.log("Participant", "\(name) state: \(state)")
        }
    }

    nonisolated public func participant(
        _ participant: Participant,
        didUpdateConnectionQuality connectionQuality: ConnectionQuality
    ) {
        Task { @MainActor in
            let name = participant.identity?.stringValue ?? participant.name ?? "participant"
            self.log("Participant", "\(name) quality: \(connectionQuality)")
        }
    }

    nonisolated public func participant(
        _ participant: Participant,
        trackPublication: TrackPublication,
        didUpdateIsMuted isMuted: Bool
    ) {
        Task { @MainActor in
            let name = participant.identity?.stringValue ?? participant.name ?? "participant"
            self.log("Track", "\(name) \(trackPublication.kind) muted: \(isMuted)")
            self.refreshTrackSummary()
        }
    }
}

// MARK: - TrackDelegate

extension LiveKitSessionManager: TrackDelegate {

    nonisolated public func track(_ track: VideoTrack, didUpdateDimensions dimensions: Dimensions?) {
        Task { @MainActor in
            if let dimensions {
                self.log("Track", "Video dimensions: \(dimensions.width)×\(dimensions.height)")
            } else {
                self.log("Track", "Video dimensions cleared")
            }
        }
    }

    nonisolated public func track(
        _ track: Track,
        didUpdateStatistics statistics: TrackStatistics,
        simulcastStatistics: [VideoCodec: TrackStatistics]
    ) {
        Task { @MainActor in
            self.log("Track", "Stats updated for \(track.name ?? String(describing: track.kind))")
        }
    }
}
