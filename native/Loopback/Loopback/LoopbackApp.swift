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
    /// Nil when no Supabase project is configured; the app still runs on local
    /// SwiftData and Settings prompts for credentials.
    let supabaseClient: SupabaseClient?

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

        // Initialize Supabase client. SupabaseClient.init traps on a malformed
        // URL, so an unconfigured build must not construct one at all.
        supabaseClient = SupabaseConfig.makeClient()
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