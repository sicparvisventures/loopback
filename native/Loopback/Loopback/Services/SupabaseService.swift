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
    
    let client: SupabaseClient
    private var modelContext: ModelContext?
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authState: AuthState = .unknown
    
    enum AuthState {
        case unknown
        case authenticated
        case unauthenticated
    }
    
    private init() {
        let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
        let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
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
            .insert(remote.toDictionary())
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
            .update(remote.toDictionary())
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
    
    func subscribeToMeetings(onChange: @escaping ([Meeting]) -> Void) -> RealtimeChannel {
        guard let userId = currentUser?.id else { fatalError("Not authenticated") }
        
        let channel = client.channel("meetings:\(userId.uuidString)")
        
        let subscription = channel
            .on(
                event: .all,
                schema: "public",
                table: "meetings",
                filter: "user_id=eq.\(userId.uuidString)"
            ) { payload in
                Task {
                    if let meetings = try? await self.fetchMeetings() {
                        await MainActor.run { onChange(meetings) }
                    }
                }
            }
            .subscribe()
        
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
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "user_id": user_id,
            "title": title,
            "platform": platform,
            "started_at": started_at,
            "status": status,
            "language": language,
            "created_at": created_at,
            "updated_at": updated_at
        ]
        
        if let platform_meeting_id { dict["platform_meeting_id"] = platform_meeting_id }
        if let ended_at { dict["ended_at"] = ended_at }
        if let duration_seconds { dict["duration_seconds"] = duration_seconds }
        if let audio_url { dict["audio_url"] = audio_url }
        if let transcript_text { dict["transcript_text"] = transcript_text }
        if let summary { dict["summary"] = summary }
        if let notes_md { dict["notes_md"] = notes_md }
        
        return dict
    }
}