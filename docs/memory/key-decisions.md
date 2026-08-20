# Key Architectural Decisions

**Started:** 2025-08-20
**Last updated:** 2026-08-21
**Author:** Dietmar (with AI assistance)

## Decision Log

### 1. Dual Platform Strategy
**Decision:** Build both Web (Next.js + Supabase) AND Native macOS (SwiftUI + SwiftData) from the start
**Rationale:** 
- Web for accessibility, team collaboration, easy sharing
- Native for best macOS integration, menu bar, offline-first, system audio capture
- Shared Supabase backend keeps data in sync

### 2. Local-First AI (Whisper.cpp + Ollama)
**Decision:** Use local AI models instead of cloud APIs
**Rationale:**
- Privacy: Audio/transcripts never leave user's machine
- Cost: No per-minute transcription fees
- Offline: Works without internet
- Quality: Whisper large-v3 matches cloud APIs for English
- Flexibility: Can swap models, fine-tune, add custom vocabulary

### 3. Meeting Bot for Audio Capture
**Decision:** Bot joins meetings as participant (Zoom/Teams/Meet)
**Rationale:**
- Best audio quality (separate streams per speaker)
- Works with any meeting platform
- Calendar integration for auto-join
- Alternative: Local recording (ScreenCaptureKit) for privacy-conscious users

### 4. Supabase as Backend
**Decision:** Use Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions)
**Rationale:**
- Managed PostgreSQL with pgvector for semantic search
- Built-in auth (email, OAuth: Google, GitHub, Microsoft)
- Realtime subscriptions for live updates
- Edge Functions for AI processing pipeline
- Generous free tier, scalable pricing

### 5. Persistent Memory System
**Decision:** Markdown + JSON index + Git for context persistence
**Rationale:**
- Human readable and editable
- Version controlled with Git
- No database dependency for memory
- Easy to search, backup, sync
- Templates for consistent documentation

### 6. SwiftData for Native Persistence
**Decision:** Use SwiftData (not Core Data directly)
**Rationale:**
- Modern Swift-native persistence
- Automatic sync with CloudKit (future)
- Type-safe queries with @Query
- Easy migration from Core Data

### 7. Next.js 14 App Router
**Decision:** Use App Router with Server Components
**Rationale:**
- Better performance with RSC
- Simplified data fetching
- Built-in SEO optimization
- Streaming and Suspense support

### 8. Public Repository
**Decision:** `sicparvisventures/loopback` is public
**Date:** 2026-08-21
**Rationale:**
- Anonymous download was a hard requirement ("men moet gewoon een .app kunnen
  downloaden of met curl")
- GitHub Release assets and `raw.githubusercontent.com` both require a token
  on a private repo, so `curl | bash` is impossible while private
- History was audited for secrets before flipping; `.env.local` was never
  tracked
**Consequence:** never commit real credentials. `web/.env.local` stays local;
production values live in Vercel env vars and repo secrets.

### 9. Runtime Credential Resolution (Native)
**Decision:** the macOS app resolves Supabase credentials at runtime, in order:
UserDefaults (Settings UI) → Info.plist (injected by CI) → environment
**Date:** 2026-08-21
**Rationale:**
- A downloadable binary cannot have a project URL and key baked into source
- `SupabaseClient.init` **traps** on a malformed URL, so the placeholder
  literals crashed the app at launch — an unconfigured build must not
  construct a client at all
- Unconfigured, Loopback still runs entirely on local SwiftData, which fits
  the local-first stance in §2
**See:** `native/Loopback/Loopback/Services/SupabaseConfig.swift`

### 10. Ad-hoc Signing, Not Notarisation (for now)
**Decision:** releases are ad-hoc signed (`codesign -s -`) and distributed
outside the App Store
**Date:** 2026-08-21
**Rationale:**
- Notarisation needs a paid Apple Developer ID; not worth it before the app
  is real
- Without *any* signature macOS refuses to launch arm64 binaries at all, so
  ad-hoc is the floor, not a choice
- `curl` does not set `com.apple.quarantine`, so the installer path has no
  Gatekeeper prompt; only browser downloads need the right-click-Open dance
**Trade-off:** ad-hoc signatures change every build, so macOS re-prompts for
Screen Recording permission after each update. A real Developer ID fixes both
this and the Gatekeeper prompt.

### 11. macos-26 CI Runner
**Decision:** native CI jobs run on `macos-26` and explicitly select the
newest Xcode on the image
**Date:** 2026-08-21
**Rationale:** supabase-swift declares `swift-tools-version:6.1`. On
`macos-15` the toolchain rejected its language-mode settings, silently
dropped the `Realtime` target, and failed 40 seconds later with the
misleading "no such module 'Realtime'". Pinning the newest Xcode makes the
failure mode impossible rather than merely unlikely.

## Tech Stack Summary

| Layer | Web | Native |
|-------|-----|--------|
| Frontend | Next.js 14, React 18, TypeScript | SwiftUI, SwiftData |
| Styling | Tailwind CSS, shadcn/ui | Native SwiftUI |
| Backend | Supabase (PostgreSQL) | Supabase (same) |
| Auth | Supabase Auth | Supabase Auth |
| Real-time | Supabase Realtime | Supabase Realtime |
| Storage | Supabase Storage | Supabase Storage |
| AI Transcription | Whisper.cpp (Edge Function) | Whisper.cpp (local binary) |
| AI Summarization | Ollama (Edge Function) | Ollama (local) |
| AI Embeddings | Ollama/nomic-embed-text | Ollama/nomic-embed-text |
| Diarization | pyannote.audio (Edge) | pyannote.audio (Python bridge) |
| Deployment | Vercel (auto on push to `main`) | GitHub Release via `scripts/build-app.sh` |

## Rejected Alternatives

| Alternative | Reason |
|-------------|--------|
| Electron/Tauri for native | Poor macOS integration, no menu bar, heavier |
| Firebase instead of Supabase | No pgvector, less SQL flexibility, vendor lock-in |
| OpenAI/Groq APIs for AI | Cost at scale, privacy concerns, rate limits |
| Core Data instead of SwiftData | Legacy API, more boilerplate |
| Pages Router (Next.js 13) | App Router is future, better performance |
| Python/FastAPI backend | More complexity, Supabase Edge Functions sufficient |

## Future Considerations

- **Mobile Apps**: React Native or Capacitor wrapper for iOS/Android
- **Team Workspaces**: Multi-tenant architecture with RLS
- **Plugin System**: MCP server for AI assistant integration
- **Custom Vocabulary**: Per-user/organization terminology
- **Real-time Transcription**: Streaming Whisper during meeting