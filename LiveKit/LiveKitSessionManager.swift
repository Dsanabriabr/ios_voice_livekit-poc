//
//  LiveKitSessionManager.swift
//  voice_to_text
//

@preconcurrency import LiveKit
import Combine
import SwiftUI

struct SessionEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let source: String
    let message: String
}

@MainActor
final class LiveKitSessionManager: NSObject, ObservableObject {

    let room: Room

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var events: [SessionEvent] = []
    @Published private(set) var participantSummary = "No participants"
    @Published private(set) var trackSummary = "No tracks"
    @Published private(set) var lastError: String?

    private let maxEvents = 50

    override init() {
        room = Room()
        super.init()
        room.add(delegate: self)
    }

    func connect(url: String, token: String) async {
        lastError = nil
        log("Room", "Connecting…")

        do {
            try await room.connect(
                url: url,
                token: token,
                connectOptions: ConnectOptions(enableMicrophone: true)
            )
            try await room.localParticipant.setMicrophone(enabled: true)
        } catch {
            lastError = error.localizedDescription
            log("Room", "Connect failed: \(error.localizedDescription)")
        }
    }

    func disconnect() async {
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

    nonisolated func room(
        _ room: Room,
        didUpdateConnectionState connectionState: ConnectionState,
        from oldConnectionState: ConnectionState
    ) {
        Task { @MainActor in
            self.connectionState = connectionState
            self.log("Room", "State: \(oldConnectionState) → \(connectionState)")
        }
    }

    nonisolated func roomDidConnect(_ room: Room) {
        Task { @MainActor in
            self.connectionState = room.connectionState
            self.registerParticipants()
            self.log("Room", "Connected to \(room.name ?? "room")")
        }
    }

    nonisolated func roomIsReconnecting(_ room: Room) {
        logOnMain("Room", "Reconnecting…")
    }

    nonisolated func roomDidReconnect(_ room: Room) {
        logOnMain("Room", "Reconnected")
    }

    nonisolated func room(_ room: Room, didFailToConnectWithError error: LiveKitError?) {
        Task { @MainActor in
            let message = error?.localizedDescription ?? "Unknown error"
            self.lastError = message
            self.log("Room", "Failed to connect: \(message)")
        }
    }

    nonisolated func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
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

    nonisolated func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        Task { @MainActor in
            participant.add(delegate: self)
            self.refreshParticipantSummary()
            let name = participant.identity?.stringValue ?? participant.name ?? "remote"
            self.log("Participant", "\(name) joined")
        }
    }

    nonisolated func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) {
        Task { @MainActor in
            self.refreshParticipantSummary()
            self.refreshTrackSummary()
            let name = participant.identity?.stringValue ?? participant.name ?? "remote"
            self.log("Participant", "\(name) left")
        }
    }

    nonisolated func room(
        _ room: Room,
        participant: LocalParticipant,
        didPublishTrack publication: LocalTrackPublication
    ) {
        Task { @MainActor in
            self.registerTrackDelegate(for: publication)
            self.log("Track", "Published local \(publication.kind)")
        }
    }

    nonisolated func room(
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

    nonisolated func room(
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

    nonisolated func participant(_ participant: Participant, didUpdateIsSpeaking isSpeaking: Bool) {
        Task { @MainActor in
            let name = participant.identity?.stringValue ?? participant.name ?? "participant"
            self.log("Participant", "\(name) speaking: \(isSpeaking)")
        }
    }

    nonisolated func participant(_ participant: Participant, didUpdateState state: ParticipantState) {
        Task { @MainActor in
            let name = participant.identity?.stringValue ?? participant.name ?? "participant"
            self.log("Participant", "\(name) state: \(state)")
        }
    }

    nonisolated func participant(
        _ participant: Participant,
        didUpdateConnectionQuality connectionQuality: ConnectionQuality
    ) {
        Task { @MainActor in
            let name = participant.identity?.stringValue ?? participant.name ?? "participant"
            self.log("Participant", "\(name) quality: \(connectionQuality)")
        }
    }

    nonisolated func participant(
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

    nonisolated func track(_ track: VideoTrack, didUpdateDimensions dimensions: Dimensions?) {
        Task { @MainActor in
            if let dimensions {
                self.log("Track", "Video dimensions: \(dimensions.width)×\(dimensions.height)")
            } else {
                self.log("Track", "Video dimensions cleared")
            }
        }
    }

    nonisolated func track(
        _ track: Track,
        didUpdateStatistics statistics: TrackStatistics,
        simulcastStatistics: [VideoCodec: TrackStatistics]
    ) {
        Task { @MainActor in
            self.log("Track", "Stats updated for \(track.name ?? String(describing: track.kind))")
        }
    }
}
