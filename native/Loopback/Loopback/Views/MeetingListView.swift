// MeetingListView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData

struct MeetingListView: View {
    let meetings: [Meeting]
    @Binding var selectedMeeting: Meeting?
    let onNewMeeting: () -> Void
    
    @State private var searchText = ""
    @State private var filterStatus: MeetingStatus = .all
    @State private var sortOrder: SortOrder = .dateDesc
    
    enum MeetingStatus: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case processing = "Processing"
        case failed = "Failed"
    }
    
    enum SortOrder: String, CaseIterable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case durationDesc = "Longest First"
        case titleAsc = "Title A-Z"
    }
    
    var filteredMeetings: [Meeting] {
        meetings.filter { meeting in
            let matchesSearch = searchText.isEmpty ||
                meeting.title.localizedCaseInsensitiveContains(searchText) ||
                meeting.transcriptText?.localizedCaseInsensitiveContains(searchText) == true ||
                meeting.summary?.localizedCaseInsensitiveContains(searchText) == true
            
            let matchesStatus = filterStatus == .all || meeting.status == filterStatus.rawValue.lowercased()
            
            return matchesSearch && matchesStatus
        }
        .sorted { lhs, rhs in
            switch sortOrder {
            case .dateDesc: return lhs.startedAt > rhs.startedAt
            case .dateAsc: return lhs.startedAt < rhs.startedAt
            case .durationDesc: return (lhs.durationSeconds ?? 0) > (rhs.durationSeconds ?? 0)
            case .titleAsc: return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search meetings...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            
            HStack {
                Picker("Status", selection: $filterStatus) {
                    ForEach(MeetingStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
                
                Spacer()
                
                Text("\(filteredMeetings.count) meetings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Meeting list
            if filteredMeetings.isEmpty {
                EmptyStateView(
                    icon: searchText.isEmpty ? "waveform.badge.mic" : "magnifyingglass",
                    title: searchText.isEmpty ? "No meetings yet" : "No results",
                    message: searchText.isEmpty ? 
                        "Create your first meeting to get started" : 
                        "Try adjusting your search or filters",
                    actionTitle: searchText.isEmpty ? "New Meeting" : nil,
                    action: onNewMeeting
                )
            } else {
                List(filteredMeetings, selection: $selectedMeeting) { meeting in
                    MeetingRowView(meeting: meeting)
                        .tag(meeting)
                }
                .listStyle(.sidebar)
            }
        }
    }
}

struct MeetingRowView: View {
    let meeting: Meeting
    
    var statusColor: Color {
        switch meeting.status {
        case "completed": return .green
        case "processing": return .blue
        case "failed": return .red
        default: return .gray
        }
    }
    
    var platformIcon: String {
        switch meeting.platform {
        case "zoom": return "video.fill"
        case "teams": return "person.2.fill"
        case "meet": return "camera.fill"
        case "local": return "mic.fill"
        default: return "calendar"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: platformIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(meeting.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // Status badge
                Text(meeting.status.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 12) {
                Label(formatDate(meeting.startedAt), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let duration = meeting.durationSeconds {
                    Label(formatDuration(duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let platform = meeting.platform.capitalized as String? {
                    Text(platform)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let summary = meeting.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Open", action: { selectedMeeting = meeting })
            Button("Copy Link") { }
            Divider()
            Button("Delete", role: .destructive) { }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    MeetingListView(meetings: [], selectedMeeting: .constant(nil), onNewMeeting: {})
        .modelContainer(for: Meeting.self, inMemory: true)
}