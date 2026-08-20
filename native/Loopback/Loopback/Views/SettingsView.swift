// SettingsView.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.supabaseClient) private var supabaseClient
    @StateObject private var supabaseService = SupabaseService.shared
    
    @AppStorage("theme") private var theme: Theme = .system
    @AppStorage("autoJoinMeetings") private var autoJoinMeetings = false
    @AppStorage("notifyOnMeetingEnd") private var notifyOnMeetingEnd = true
    @AppStorage("weeklyDigest") private var weeklyDigest = false
    @AppStorage("whisperModel") private var whisperModel = "large-v3"
    @AppStorage("whisperPath") private var whisperPath = "/opt/homebrew/bin/whisper-cli"
    @AppStorage("modelPath") private var modelPath = "/opt/homebrew/share/whisper.cpp/models/ggml-large-v3.bin"

    @State private var supabaseURL = SupabaseConfig.urlString ?? ""
    @State private var supabaseAnonKey = SupabaseConfig.anonKey ?? ""
    @State private var didSaveCredentials = false
    
    enum Theme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }
    
    var body: some View {
        Form {
            Section("Supabase Connection") {
                if !supabaseService.isConfigured {
                    Label(
                        "Not connected. Loopback works offline on this Mac; add your project URL and anon key to sync.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                }

                TextField("Project URL", text: $supabaseURL, prompt: Text("https://your-project.supabase.co"))
                    .textFieldStyle(.roundedBorder)

                SecureField("Anon Key", text: $supabaseAnonKey, prompt: Text("eyJhbGci..."))
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save Connection") {
                        SupabaseConfig.save(urlString: supabaseURL, anonKey: supabaseAnonKey)
                        supabaseService.reloadConfiguration()
                        didSaveCredentials = true
                    }
                    .buttonStyle(.borderedProminent)

                    if didSaveCredentials {
                        Label(
                            supabaseService.isConfigured ? "Saved" : "URL or key looks invalid",
                            systemImage: supabaseService.isConfigured ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(supabaseService.isConfigured ? .green : .red)
                    }
                }
            }

            Section("Account") {
                if let user = supabaseService.currentUser {
                    HStack {
                        AsyncImage(url: URL(string: user.userMetadata["avatar_url"]?.stringValue ?? "")) { image in
                            image.resizable()
                        } placeholder: {
                            Circle().fill(Color.accentColor.opacity(0.2))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(user.userMetadata["full_name"]?.stringValue ?? user.email ?? "User")
                                .font(.headline)
                            Text(user.email ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button("Sign Out", role: .destructive) {
                        Task { try? await supabaseService.signOut() }
                    }
                } else {
                    Button("Sign In") {
                        // Show sign in
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    ForEach(Theme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
            }
            
            Section("Meeting Behavior") {
                Toggle("Auto-join calendar meetings", isOn: $autoJoinMeetings)
                Toggle("Notify when meeting ends", isOn: $notifyOnMeetingEnd)
                Toggle("Weekly digest email", isOn: $weeklyDigest)
            }
            
            Section("AI Settings") {
                Picker("Whisper Model", selection: $whisperModel) {
                    Text("Tiny (fastest)").tag("tiny")
                    Text("Base").tag("base")
                    Text("Small").tag("small")
                    Text("Medium").tag("medium")
                    Text("Large v3 (best)").tag("large-v3")
                }
                
                LabeledContent("Whisper.cpp Path") {
                    Text(whisperPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                LabeledContent("Model Path") {
                    Text(modelPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Section("Data") {
                Button("Export All Data") {
                    // Export
                }
                
                Button("Clear Local Cache", role: .destructive) {
                    // Clear cache
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                Link("Privacy Policy", destination: URL(string: "https://loopback.ai/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://loopback.ai/terms")!)
                Link("Documentation", destination: URL(string: "https://docs.loopback.ai")!)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            supabaseService.configure(with: modelContext)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Meeting.self, TranscriptSegment.self, ActionItem.self, Speaker.self], inMemory: true)
}