// MenuBarView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.supabaseClient) private var supabaseClient
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingNewMeeting = false
    @State private var showingSettings = false
    
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform.badge.mic")
                    .font(.title2)
                    .foregroundStyle(.accent)
                Text("Loopback")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Quick actions
            VStack(spacing: 4) {
                MenuBarButton(
                    title: "New Meeting",
                    icon: "plus.circle",
                    action: { showingNewMeeting = true }
                )
                
                MenuBarButton(
                    title: "Recent Meetings",
                    icon: "clock.arrow.circlepath",
                    action: { }
                ) {
                    ForEach(meetings.prefix(5)) { meeting in
                        Button(meeting.title) {
                            // Open meeting
                        }
                    }
                }
                
                if audioRecorder.isRecording {
                    MenuBarButton(
                        title: "Recording...",
                        icon: "record.circle.fill",
                        action: { }
                    )
                } else {
                    MenuBarButton(
                        title: "Start Recording",
                        icon: "mic.fill",
                        action: { }
                    )
                }
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // Status
            HStack {
                Circle()
                    .fill(supabaseService.isAuthenticated ? .green : .red)
                    .frame(width: 8, height: 8)
                Text(supabaseService.isAuthenticated ? "Connected" : "Not signed in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
            
            // Footer actions
            HStack {
                Button("Settings") { showingSettings = true }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(width: 280)
        .sheet(isPresented: $showingNewMeeting) {
            NewMeetingView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            supabaseService.configure(with: modelContext)
        }
    }
}

struct MenuBarButton<MenuContent: View>: View {
    let title: String
    let icon: String
    let action: () -> Void
    @ViewBuilder let menuContent: () -> MenuContent
    
    init(title: String, icon: String, action: @escaping () -> Void, @ViewBuilder menuContent: @escaping () -> MenuContent = { EmptyView() }) {
        self.title = title
        self.icon = icon
        self.action = action
        self.menuContent = menuContent
    }
    
    var body: some View {
        Menu {
            menuContent()
        } label: {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
    }
}

#Preview {
    MenuBarView()
        .modelContainer(for: Meeting.self, inMemory: true)
}