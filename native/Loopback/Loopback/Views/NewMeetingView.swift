// NewMeetingView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData

struct NewMeetingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var audioRecorder = AudioRecorder()
    
    @State private var title = ""
    @State private var platform: MeetingPlatform = .manual
    @State private var startedAt = Date()
    @State private var durationMinutes = 30
    @State private var isRecording = false
    @State private var recordingURL: URL?
    @State private var errorMessage: String?
    
    enum MeetingPlatform: String, CaseIterable {
        case manual = "Manual Entry"
        case zoom = "Zoom"
        case teams = "Microsoft Teams"
        case meet = "Google Meet"
        case local = "Local Recording"
        
        var icon: String {
            switch self {
            case .manual: return "doc.text"
            case .zoom: return "video.fill"
            case .teams: return "person.2.fill"
            case .meet: return "camera.fill"
            case .local: return "mic.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Meeting Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Platform", selection: $platform) {
                        ForEach(MeetingPlatform.allCases, id: \.self) { platform in
                            Label(platform.rawValue, systemImage: platform.icon)
                                .tag(platform)
                        }
                    }
                    
                    DatePicker("Date & Time", selection: $startedAt)
                    
                    Stepper("Duration: \(durationMinutes) minutes", value: $durationMinutes, in: 1...480, step: 5)
                }
                
                if platform == .local {
                    Section("Local Recording") {
                        if isRecording {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("Recording...")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                    Spacer()
                                    Text(formatDuration(audioRecorder.recordingDuration))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Audio level meter
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.secondary.opacity(0.2))
                                        Rectangle()
                                            .fill(Color.accentColor)
                                            .frame(width: geometry.size.width * CGFloat(audioRecorder.audioLevel))
                                    }
                                    .cornerRadius(2)
                                }
                                .frame(height: 4)
                                
                                HStack {
                                    Button("Pause") {
                                        // Pause recording
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Spacer()
                                    
                                    Button("Stop Recording") {
                                        stopRecording()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                }
                            }
                        } else {
                            Button(action: startRecording) {
                                Label("Start Recording", systemImage: "record.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                        }
                        
                        if let url = recordingURL {
                            HStack {
                                Image(systemName: "doc.fill")
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                                Spacer()
                                Button("Play") {
                                    // Play recording
                                }
                                .buttonStyle(.bordered)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
            .frame(width: 500, height: 600)
            .navigationTitle("New Meeting")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createMeeting()
                    }
                    .disabled(title.isEmpty || (platform == .local && isRecording))
                }
            }
        }
    }
    
    private func startRecording() {
        errorMessage = nil
        Task {
            do {
                try await audioRecorder.startRecording()
                isRecording = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func stopRecording() {
        Task {
            if let url = await audioRecorder.stopRecording() {
                recordingURL = url
            }
            isRecording = false
        }
    }
    
    private func createMeeting() {
        let meeting = Meeting(
            userId: supabaseService.currentUser?.id ?? UUID(),
            title: title,
            platform: platform.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"),
            startedAt: startedAt,
            endedAt: Date().addingTimeInterval(TimeInterval(durationMinutes * 60)),
            durationSeconds: durationMinutes * 60,
            status: "completed",
            language: "en",
            audioUrl: recordingURL?.absoluteString
        )
        
        modelContext.insert(meeting)
        
        // Also save to Supabase if authenticated
        if supabaseService.isAuthenticated {
            Task {
                try? await supabaseService.createMeeting(meeting)
            }
        }
        
        dismiss()
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NewMeetingView()
        .modelContainer(for: Meeting.self, inMemory: true)
}