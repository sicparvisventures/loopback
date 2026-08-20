// LoopbackApp.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import SwiftUI
import SwiftData
import Supabase

@main
struct LoopbackApp: App {
    let container: ModelContainer
    let supabaseClient: SupabaseClient

    init() {
        // Configure SwiftData container
        let schema = Schema([
            Meeting.self,
            TranscriptSegment.self,
            ActionItem.self,
            Speaker.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Initialize Supabase client
        let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
        let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
        supabaseClient = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(\.supabaseClient, supabaseClient)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        
        // Menu bar extra
        MenuBarExtra("Loopback", systemImage: "waveform.badge.mic") {
            MenuBarView()
                .modelContainer(container)
                .environment(\.supabaseClient, supabaseClient)
        }
        
        // Settings
        Settings {
            SettingsView()
                .modelContainer(container)
                .environment(\.supabaseClient, supabaseClient)
        }
    }
}

// Environment key for Supabase client
struct SupabaseClientKey: EnvironmentKey {
    static let defaultValue: SupabaseClient? = nil
}

extension EnvironmentValues {
    var supabaseClient: SupabaseClient? {
        get { self[SupabaseClientKey.self] }
        set { self[SupabaseClientKey.self] = newValue }
    }
}