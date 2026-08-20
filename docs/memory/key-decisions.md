# Key Architectural Decisions

**Date:** 2025-08-20
**Author:** Dietmar (with opencode assistance)

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
| Deployment | Vercel | Xcode Archive / TestFlight |

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