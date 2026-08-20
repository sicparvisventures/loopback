// SupabaseService.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import Foundation
import Supabase
import SwiftData

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    /// Nil until Supabase credentials are supplied; see `SupabaseConfig`.
    private var storedClient: SupabaseClient?
    private var modelContext: ModelContext?

    /// Throws instead of trapping when the app is not connected to a project.
    /// Every call site is already inside a `try`, so the guard costs nothing.
    var client: SupabaseClient {
        get throws {
            if let storedClient { return storedClient }
            guard let client = SupabaseConfig.makeClient() else {
                throw SupabaseConfigError.notConfigured
            }
            storedClient = client
            return client
        }
    }

    /// Whether cloud sync is available at all. Drives the Settings banner.
    var isConfigured: Bool { SupabaseConfig.isConfigured }
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authState: AuthState = .unknown
    
    enum AuthState {
        case unknown
        case authenticated
        case unauthenticated
    }
    
    private init() {}

    /// Re-reads credentials after the user edits them in Settings.
    func reloadConfiguration() {
        storedClient = nil
        Task { await checkAuthState() }
    }
    
    func configure(with context: ModelContext) {
        self.modelContext = context
        Task { await checkAuthState() }
    }
    
    func checkAuthState() async {
        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
            authState = .authenticated
        } catch {
            currentUser = nil
            isAuthenticated = false
            authState = .unauthenticated
        }
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
        authState = .authenticated
    }
    
    func signUp(email: String, password: String) async throws {
        let session = try await client.auth.signUp(email: email, password: password)
        currentUser = session.user
        isAuthenticated = true
        authState = .authenticated
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
        authState = .unauthenticated
    }
    
    // MARK: - Meetings
    
    func fetchMeetings(limit: Int = 50) async throws -> [Meeting] {
        guard let userId = currentUser?.id else { throw AuthError.notAuthenticated }
        
        let response: [RemoteMeeting] = try await client
            .from("meetings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("started_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response.map { $0.toLocal() }
    }
    
    func fetchMeeting(id: UUID) async throws -> Meeting? {
        guard let userId = currentUser?.id else { throw AuthError.notAuthenticated }
        
        let response: [RemoteMeeting] = try await client
            .from("meetings")
            .select()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return response.first?.toLocal()
    }
    
    func createMeeting(_ meeting: Meeting) async throws -> Meeting {
        guard let userId = currentUser?.id else { throw AuthError.notAuthenticated }
        
        let remote = RemoteMeeting(from: meeting, userId: userId)
        let response: RemoteMeeting = try await client
            .from("meetings")
            .insert(remote)
            .select()
            .single()
            .execute()
            .value
        
        return response.toLocal()
    }
    
    func updateMeeting(_ meeting: Meeting) async throws {
        guard let userId = currentUser?.id else { throw AuthError.notAuthenticated }
        
        let remote = RemoteMeeting(from: meeting, userId: userId)
        try await client
            .from("meetings")
            .update(remote)
            .eq("id", value: meeting.id.uuidString)
            .execute()
    }
    
    func deleteMeeting(id: UUID) async throws {
        guard let userId = currentUser?.id else { throw AuthError.notAuthenticated }
        
        try await client
            .from("meetings")
            .delete()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    // MARK: - Real-time subscriptions
    
    /// Streams every change to the caller's meetings.
    ///
    /// The returned channel must be kept alive by the caller and torn down with
    /// `await channel.unsubscribe()`.
    func subscribeToMeetings(onChange: @escaping @Sendable ([Meeting]) -> Void) async throws -> RealtimeChannelV2 {
        guard let userId = currentUser?.id else { throw AuthError.notAuthenticated }

        let channel = try client.channel("meetings:\(userId.uuidString)")
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "meetings",
            filter: "user_id=eq.\(userId.uuidString)"
        )
        await channel.subscribe()

        Task { [weak self] in
            for await _ in changes {
                guard let self else { return }
                if let meetings = try? await self.fetchMeetings() {
                    onChange(meetings)
                }
            }
        }

        return channel
    }
    
    // MARK: - Storage
    
    func uploadAudio(_ data: Data, path: String) async throws -> String {
        try await client.storage
            .from("meeting-audio")
            .upload(path, data: data, options: FileOptions(contentType: "audio/wav"))
        
        let publicURL = try client.storage
            .from("meeting-audio")
            .getPublicURL(path: path)
        
        return publicURL.absoluteString
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "User not authenticated"
        case .invalidCredentials: return "Invalid credentials"
        }
    }
}

// Remote models for Supabase
struct RemoteMeeting: Codable {
    let id: String
    let user_id: String
    let title: String
    let platform: String
    let platform_meeting_id: String?
    let started_at: String
    let ended_at: String?
    let duration_seconds: Int?
    let status: String
    let language: String
    let audio_url: String?
    let transcript_text: String?
    let summary: String?
    let notes_md: String?
    let created_at: String
    let updated_at: String
    
    init(from meeting: Meeting, userId: UUID) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.id = meeting.id.uuidString
        self.user_id = userId.uuidString
        self.title = meeting.title
        self.platform = meeting.platform
        self.platform_meeting_id = meeting.platformMeetingId
        self.started_at = formatter.string(from: meeting.startedAt)
        self.ended_at = meeting.endedAt.map { formatter.string(from: $0) }
        self.duration_seconds = meeting.durationSeconds
        self.status = meeting.status
        self.language = meeting.language
        self.audio_url = meeting.audioUrl
        self.transcript_text = meeting.transcriptText
        self.summary = meeting.summary
        self.notes_md = meeting.notesMd
        self.created_at = formatter.string(from: meeting.createdAt)
        self.updated_at = formatter.string(from: meeting.updatedAt)
    }
    
    func toLocal() -> Meeting {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return Meeting(
            id: UUID(uuidString: id) ?? UUID(),
            userId: UUID(uuidString: user_id) ?? UUID(),
            title: title,
            platform: platform,
            platformMeetingId: platform_meeting_id,
            startedAt: formatter.date(from: started_at) ?? Date(),
            endedAt: ended_at.flatMap { formatter.date(from: $0) },
            durationSeconds: duration_seconds,
            status: status,
            language: language,
            audioUrl: audio_url,
            transcriptText: transcript_text,
            summary: summary,
            notesMd: notes_md,
            createdAt: formatter.date(from: created_at) ?? Date(),
            updatedAt: formatter.date(from: updated_at) ?? Date()
        )
    }
    
}