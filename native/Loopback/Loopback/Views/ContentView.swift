// ContentView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.supabaseClient) private var supabaseClient
    @StateObject private var supabaseService = SupabaseService.shared
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var transcriptionService = TranscriptionService()
    
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @State private var selectedMeeting: Meeting?
    @State private var showingNewMeeting = false
    @State private var sidebarSelection: SidebarItem? = .meetings
    
    enum SidebarItem: Hashable {
        case meetings
        case calendar
        case actions
        case search
        case settings
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $sidebarSelection) {
                Section("Loopback") {
                    Label("Meetings", systemImage: "waveform.badge.mic")
                        .tag(SidebarItem.meetings)
                    Label("Calendar", systemImage: "calendar")
                        .tag(SidebarItem.calendar)
                    Label("Action Items", systemImage: "checklist")
                        .tag(SidebarItem.actions)
                    Label("Search", systemImage: "magnifyingglass")
                        .tag(SidebarItem.search)
                }
                
                Section {
                    Label("Settings", systemImage: "gear")
                        .tag(SidebarItem.settings)
                }
            }
            .navigationTitle("Loopback")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewMeeting = true }) {
                        Label("New Meeting", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // Detail view
            switch sidebarSelection {
            case .meetings:
                MeetingListView(
                    meetings: meetings,
                    selectedMeeting: $selectedMeeting,
                    onNewMeeting: { showingNewMeeting = true }
                )
            case .calendar:
                CalendarView()
            case .actions:
                ActionsView()
            case .search:
                SearchView()
            case .settings:
                SettingsView()
            case .none:
                WelcomeView()
            }
        }
        .sheet(isPresented: $showingNewMeeting) {
            NewMeetingView()
        }
        .sheet(item: $selectedMeeting) { meeting in
            MeetingDetailView(meeting: meeting)
        }
        .onAppear {
            supabaseService.configure(with: modelContext)
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.badge.mic")
                .font(.system(size: 64))
                .foregroundStyle(.primary)
            
            Text("Welcome to Loopback")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("AI-powered meeting notes that capture every detail")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                FeatureRow(icon: "mic.fill", title: "Automatic Transcription", description: "Real-time with 95%+ accuracy")
                FeatureRow(icon: "doc.text.fill", title: "Structured Notes", description: "AI-generated summaries & action items")
                FeatureRow(icon: "magnifyingglass", title: "Search Everything", description: "Find any conversation instantly")
                FeatureRow(icon: "lock.fill", title: "Privacy First", description: "Local AI processing on your Mac")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.accent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Meeting.self, TranscriptSegment.self, ActionItem.self, Speaker.self], inMemory: true)
}