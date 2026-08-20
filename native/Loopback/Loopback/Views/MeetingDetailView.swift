// MeetingDetailView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData

struct MeetingDetailView: View {
    let meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .overview
    
    enum Tab: String, CaseIterable {
        case overview = "Overview"
        case transcript = "Transcript"
        case notes = "Notes"
        case actions = "Actions"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            MeetingDetailHeader(meeting: meeting, onClose: { dismiss() })
            
            // Tab bar
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            ScrollView {
                switch selectedTab {
                case .overview:
                    OverviewTab(meeting: meeting)
                case .transcript:
                    TranscriptTab(meeting: meeting)
                case .notes:
                    NotesTab(meeting: meeting)
                case .actions:
                    ActionsTab(meeting: meeting)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

struct MeetingDetailHeader: View {
    let meeting: Meeting
    let onClose: () -> Void
    
    var platformIcon: String {
        switch meeting.platform {
        case "zoom": return "video.fill"
        case "teams": return "person.2.fill"
        case "meet": return "camera.fill"
        case "local": return "mic.fill"
        default: return "calendar"
        }
    }
    
    var statusColor: Color {
        switch meeting.status {
        case "completed": return .green
        case "processing": return .blue
        case "failed": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: platformIcon)
                .font(.title)
                .foregroundStyle(.accent)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 12) {
                    Label(formatDate(meeting.startedAt), systemImage: "calendar")
                    if let duration = meeting.durationSeconds {
                        Label(formatDuration(duration), systemImage: "clock")
                    }
                    Text(meeting.platform.capitalized)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status
            VStack(alignment: .trailing, spacing: 4) {
                Text(meeting.status.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
                
                if meeting.status == "processing" {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            
            // Actions
            Menu {
                Button("Export as PDF") { }
                Button("Export as Markdown") { }
                Button("Export as JSON") { }
                Divider()
                Button("Share") { }
                Divider()
                Button("Delete", role: .destructive) { }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
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
        if hours > 0 { return "\(hours)h \(minutes % 60)m" }
        return "\(minutes)m"
    }
}

struct OverviewTab: View {
    let meeting: Meeting
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Summary
            if let summary = meeting.summary, !summary.isEmpty {
                SectionCard(title: "Summary", icon: "doc.text") {
                    Text(summary)
                        .textSelection(.enabled)
                }
            }
            
            // Metadata
            SectionCard(title: "Meeting Details", icon: "info.circle") {
                DetailGrid(items: [
                    ("Title", meeting.title),
                    ("Platform", meeting.platform.capitalized),
                    ("Date", formatFullDate(meeting.startedAt)),
                    ("Duration", meeting.durationSeconds.map(formatDuration) ?? "—"),
                    ("Language", meeting.language.uppercased()),
                    ("Status", meeting.status.capitalized),
                ])
            }
            
            // Quick actions
            SectionCard(title: "Quick Actions", icon: "bolt") {
                HStack(spacing: 12) {
                    ActionButton(title: "View Transcript", icon: "doc.text", action: { })
                    ActionButton(title: "View Notes", icon: "note.text", action: { })
                    ActionButton(title: "View Actions", icon: "checklist", action: { })
                    ActionButton(title: "Export", icon: "square.and.arrow.up", action: { })
                }
            }
        }
        .padding()
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let hours = minutes / 60
        if hours > 0 { return "\(hours)h \(minutes % 60)m" }
        return "\(minutes)m"
    }
}

struct TranscriptTab: View {
    let meeting: Meeting
    @State private var searchText = ""
    
    var filteredSegments: [TranscriptSegment] {
        if searchText.isEmpty {
            return meeting.transcriptSegments.sorted { $0.sequence < $1.sequence }
        }
        return meeting.transcriptSegments
            .filter { $0.text.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.sequence < $1.sequence }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search transcript...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding()
            
            if meeting.transcriptSegments.isEmpty {
                EmptyStateView(
                    icon: "waveform",
                    title: "No transcript available",
                    message: meeting.status == "processing" ? 
                        "Transcript is being generated..." : 
                        "No transcript was generated for this meeting",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                List(filteredSegments) { segment in
                    TranscriptSegmentRow(segment: segment)
                }
                .listStyle(.plain)
            }
        }
    }
}

struct TranscriptSegmentRow: View {
    let segment: TranscriptSegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(segment.speakerName ?? segment.speakerId)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
                
                Text(formatTime(segment.startMs))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            Text(segment.text)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
    }
    
    private func formatTime(_ ms: Int) -> String {
        let seconds = ms / 1000
        let minutes = seconds / 60
        let hours = minutes / 60
        return String(format: "%02d:%02d:%02d", hours, minutes % 60, seconds % 60)
    }
}

struct NotesTab: View {
    let meeting: Meeting
    
    var body: some View {
        ScrollView {
            if let notes = meeting.notesMd, !notes.isEmpty {
                // Render markdown (basic)
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(parseMarkdown(notes), id: \.self) { block in
                        MarkdownBlock(block: block)
                    }
                }
                .padding()
                .textSelection(.enabled)
            } else {
                EmptyStateView(
                    icon: "note.text",
                    title: "No notes available",
                    message: "AI-generated notes will appear here after processing",
                    actionTitle: nil,
                    action: nil
                )
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> [String] {
        // Simple markdown parsing - split by double newlines
        text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}

struct MarkdownBlock: View {
    let block: String
    
    var body: some View {
        if block.hasPrefix("# ") {
            Text(block.dropFirst(2))
                .font(.title)
                .fontWeight(.bold)
        } else if block.hasPrefix("## ") {
            Text(block.dropFirst(3))
                .font(.title2)
                .fontWeight(.semibold)
        } else if block.hasPrefix("- ") || block.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                Text(block.dropFirst(2))
            }
        } else if block.hasPrefix("1. ") {
            HStack(alignment: .top, spacing: 8) {
                Text("1.")
                Text(block.dropFirst(3))
            }
        } else {
            Text(block)
        }
    }
}

struct ActionsTab: View {
    let meeting: Meeting
    
    var body: some View {
        if meeting.actionItems.isEmpty {
            EmptyStateView(
                icon: "checklist",
                title: "No action items",
                message: "Action items will be extracted automatically after processing",
                actionTitle: nil,
                action: nil
            )
        } else {
            List(meeting.actionItems) { action in
                ActionItemRow(action: action)
            }
            .listStyle(.plain)
        }
    }
}

struct ActionItemRow: View {
    let action: ActionItem
    
    var priorityColor: Color {
        switch action.priority {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
    
    var statusColor: Color {
        switch action.status {
        case "done": return .green
        case "in_progress": return .blue
        case "open": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(action.title)
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(action.priority.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.15))
                        .foregroundStyle(priorityColor)
                        .clipShape(Capsule())
                    
                    Text(action.status.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.15))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
            }
            
            if let description = action.descriptionText, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                if let assignee = action.assigneeName {
                    Label(assignee, systemImage: "person")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let dueDate = action.dueDate {
                    Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// Reusable components
struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailGrid: View {
    let items: [(String, String)]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.fixed(120), alignment: .leading), GridItem(.flexible())], spacing: 8) {
            ForEach(items, id: \.0) { label, value in
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .textSelection(.enabled)
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}