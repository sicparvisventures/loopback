// ActionsView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData

struct ActionsView: View {
    @Query(sort: \ActionItem.createdAt, order: .reverse) private var actions: [ActionItem]
    @State private var searchText = ""
    @State private var filterStatus: ActionStatus = .all
    @State private var showingNewAction = false
    
    enum ActionStatus: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case inProgress = "In Progress"
        case done = "Done"
    }
    
    var filteredActions: [ActionItem] {
        actions.filter { action in
            let matchesSearch = searchText.isEmpty ||
                action.title.localizedCaseInsensitiveContains(searchText) ||
                action.descriptionText?.localizedCaseInsensitiveContains(searchText) == true ||
                action.assigneeName?.localizedCaseInsensitiveContains(searchText) == true
            
            let matchesStatus = filterStatus == .all || action.status == filterStatus.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")
            
            return matchesSearch && matchesStatus
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search action items...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
            
            HStack {
                Picker("Status", selection: $filterStatus) {
                    ForEach(ActionStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                
                Spacer()
                
                Text("\(filteredActions.count) actions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(action: { showingNewAction = true }) {
                    Label("New Action", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Kanban board
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(KanbanColumn.allCases, id: \.self) { column in
                        KanbanColumnView(
                            column: column,
                            actions: filteredActions.filter { $0.status == column.rawValue },
                            onMove: { action, newStatus in
                                // Update action status
                            }
                        )
                    }
                }
                .padding()
            }
            
            if filteredActions.isEmpty {
                EmptyStateView(
                    icon: "checklist",
                    title: "No action items",
                    message: searchText.isEmpty ? "Action items from meetings will appear here" : "No matching action items found",
                    actionTitle: "Create Action",
                    action: { showingNewAction = true }
                )
            }
        }
        .sheet(isPresented: $showingNewAction) {
            NewActionView()
        }
    }
}

enum KanbanColumn: String, CaseIterable {
    case open = "open"
    case in_progress = "in_progress"
    case done = "done"
    
    var title: String {
        switch self {
        case .open: return "To Do"
        case .in_progress: return "In Progress"
        case .done: return "Done"
        }
    }
    
    var color: Color {
        switch self {
        case .open: return .orange
        case .in_progress: return .blue
        case .done: return .green
        }
    }
}

struct KanbanColumnView: View {
    let column: KanbanColumn
    let actions: [ActionItem]
    let onMove: (ActionItem, KanbanColumn) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column header
            HStack {
                Circle()
                    .fill(column.color)
                    .frame(width: 10, height: 10)
                Text(column.title)
                    .font(.headline)
                Spacer()
                Text("\(actions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(Capsule())
            }
            
            // Actions
            VStack(spacing: 8) {
                ForEach(actions) { action in
                    ActionCard(action: action)
                        .onDrag {
                            NSItemProvider(object: action.id.uuidString as NSString)
                        }
                }
                
                Spacer()
            }
        }
        .frame(width: 300)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ActionCard: View {
    let action: ActionItem
    
    var priorityColor: Color {
        switch action.priority {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(action.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Spacer()
                
                Text(action.priority.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.15))
                    .foregroundStyle(priorityColor)
                    .clipShape(Capsule())
            }
            
            if let description = action.descriptionText, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let assignee = action.assigneeName {
                    Label(assignee, systemImage: "person.fill")
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
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct NewActionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var assignee = ""
    @State private var dueDate = Date().addingTimeInterval(86400 * 7)
    @State private var priority = "medium"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Assignment") {
                    TextField("Assignee", text: $assignee)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    Picker("Priority", selection: $priority) {
                        Text("High").tag("high")
                        Text("Medium").tag("medium")
                        Text("Low").tag("low")
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
            .frame(width: 500, height: 500)
            .navigationTitle("New Action Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        // Create action
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ActionsView()
        .modelContainer(for: ActionItem.self, inMemory: true)
}