// SupabaseConfig.swift
// Loopback
//

import Foundation
import Supabase

/// Where the app gets its Supabase credentials from.
///
/// A distributed build cannot ship a project URL baked into the source, and
/// `SupabaseClient.init` traps on a malformed URL — so the credentials are
/// resolved at runtime and the app stays usable (local SwiftData only) until
/// they are supplied.
///
/// Resolution order, first hit wins:
///  1. `UserDefaults` — what the user typed in Settings.
///  2. `Info.plist` keys `SupabaseURL` / `SupabaseAnonKey` — baked in at build
///     time by CI when the corresponding secrets exist.
///  3. Environment `SUPABASE_URL` / `SUPABASE_ANON_KEY` — handy for `swift run`.
enum SupabaseConfig {
    static let urlDefaultsKey = "supabase.url"
    static let anonKeyDefaultsKey = "supabase.anonKey"

    static var urlString: String? {
        firstNonEmpty(
            UserDefaults.standard.string(forKey: urlDefaultsKey),
            Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
            ProcessInfo.processInfo.environment["SUPABASE_URL"]
        )
    }

    static var anonKey: String? {
        firstNonEmpty(
            UserDefaults.standard.string(forKey: anonKeyDefaultsKey),
            Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String,
            ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
        )
    }

    /// A URL only counts as configured when it is absolute and http(s) — the
    /// exact condition `SupabaseClient` traps on.
    static var url: URL? {
        guard let urlString, let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              url.host != nil
        else { return nil }
        return url
    }

    static var isConfigured: Bool { url != nil && anonKey != nil }

    /// Returns nil rather than trapping when credentials are missing or bad.
    static func makeClient() -> SupabaseClient? {
        guard let url, let anonKey else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    /// Persists credentials entered in Settings. Pass nil/empty to clear.
    static func save(urlString: String?, anonKey: String?) {
        let defaults = UserDefaults.standard
        set(defaults, urlDefaultsKey, urlString)
        set(defaults, anonKeyDefaultsKey, anonKey)
    }

    private static func set(_ defaults: UserDefaults, _ key: String, _ value: String?) {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            defaults.set(trimmed, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private static func firstNonEmpty(_ candidates: String?...) -> String? {
        for candidate in candidates {
            let trimmed = candidate?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let trimmed, !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
}

enum SupabaseConfigError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Loopback is not connected to a Supabase project yet. Add your project URL and anon key in Settings."
        }
    }
}
