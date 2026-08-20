// SearchView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @State private var searchText = ""
    @State private var searchType: SearchType = .fullText
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    
    enum SearchType: String, CaseIterable {
        case fullText = "Full Text"
        case semantic = "Semantic"
        
        var icon: String {
            switch self {
            case .fullText: return "doc.text.magnifyingglass"
            case .semantic: return "brain"
            }
        }
    }
    
    struct SearchResult: Identifiable {
        let id = UUID()
        let meeting: Meeting
        let matchedText: String
        let matchType: MatchType
        
        enum MatchType {
            case title
            case transcript
            case summary
            case notes
            case actionItem
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search all meetings, transcripts, notes, and actions...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit { performSearch() }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Search type selector
                Picker("Search Type", selection: $searchType) {
                    ForEach(SearchType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding()
            
            // Results
            if isSearching {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Search your meetings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Enter a query to search across transcripts, notes, action items, and more")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if results.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No results found")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Try different keywords or switch search type")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(results) { result in
                    SearchResultRow(result: result)
                }
                .listStyle(.plain)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        
        // Simulate async search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var foundResults: [SearchResult] = []
            let query = searchText.lowercased()
            
            for meeting in meetings {
                // Search title
                if meeting.title.lowercased().contains(query) {
                    foundResults.append(SearchResult(
                        meeting: meeting,
                        matchedText: meeting.title,
                        matchType: .title
                    ))
                }
                
                // Search transcript
                if let transcript = meeting.transcriptText?.lowercased(),
                   transcript.contains(query) {
                    // Find context around match
                    let context = extractContext(from: meeting.transcriptText ?? "", query: query)
                    foundResults.append(SearchResult(
                        meeting: meeting,
                        matchedText: context,
                        matchType: .transcript
                    ))
                }
                
                // Search summary
                if let summary = meeting.summary?.lowercased(),
                   summary.contains(query) {
                    foundResults.append(SearchResult(
                        meeting: meeting,
                        matchedText: meeting.summary ?? "",
                        matchType: .summary
                    ))
                }
                
                // Search notes
                if let notes = meeting.notesMd?.lowercased(),
                   notes.contains(query) {
                    let context = extractContext(from: meeting.notesMd ?? "", query: query)
                    foundResults.append(SearchResult(
                        meeting: meeting,
                        matchedText: context,
                        matchType: .notes
                    ))
                }
                
                // Search action items
                for action in meeting.actionItems {
                    if action.title.lowercased().contains(query) ||
                       action.descriptionText?.lowercased().contains(query) == true {
                        foundResults.append(SearchResult(
                            meeting: meeting,
                            matchedText: action.title,
                            matchType: .actionItem
                        ))
                    }
                }
            }
            
            results = foundResults
            isSearching = false
        }
    }
    
    private func extractContext(from text: String, query: String, contextLength: Int = 100) -> String {
        let lowerText = text.lowercased()
        guard let range = lowerText.range(of: query) else { return String(text.prefix(contextLength)) }
        
        let start = max(text.startIndex, text.index(range.lowerBound, offsetBy: -contextLength/2, limitedBy: text.startIndex) ?? text.startIndex)
        let end = min(text.endIndex, text.index(range.upperBound, offsetBy: contextLength/2, limitedBy: text.endIndex) ?? text.endIndex)
        
        var result = String(text[start..<end])
        if start > text.startIndex { result = "..." + result }
        if end < text.endIndex { result = result + "..." }
        return result
    }
}

struct SearchResultRow: View {
    let result: SearchView.SearchResult
    
    var matchIcon: String {
        switch result.matchType {
        case .title: return "textformat"
        case .transcript: return "waveform"
        case .summary: return "doc.text"
        case .notes: return "note.text"
        case .actionItem: return "checklist"
        }
    }
    
    var matchColor: Color {
        switch result.matchType {
        case .title: return .blue
        case .transcript: return .purple
        case .summary: return .green
        case .notes: return .orange
        case .actionItem: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: matchIcon)
                    .foregroundStyle(matchColor)
                
                Text(result.meeting.title)
                    .font(.headline)
                
                Spacer()
                
                Text(result.matchType.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(matchColor.opacity(0.15))
                    .foregroundStyle(matchColor)
                    .clipShape(Capsule())
                
                Text(result.meeting.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(result.matchedText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SearchView()
        .modelContainer(for: Meeting.self, inMemory: true)
}