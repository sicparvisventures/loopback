# Loopback - Bootstrap Context

## Project: Loopback
**Initialized:** 2025-08-20
**Last updated:** 2026-08-21
**Version:** 0.1.0 (first macOS release shipped)
**Repo:** https://github.com/sicparvisventures/loopback (public)
**Live web:** https://loopback-taupe.vercel.app

## Quick Context for New Sessions

### What is this project?
A Circleback.ai clone for personal/team use - AI-powered meeting notes with transcription, speaker diarization, structured notes, action items, and search across all meetings. Built with local-first AI (Whisper.cpp + Ollama), webapp (Next.js + Supabase), and native macOS app (Swift/SwiftUI).

### Current Phase
**Shipping infrastructure done, features next.** Both apps build, CI is green,
`main` auto-deploys to Vercel, and `v0.1.0` of the macOS app is downloadable.
The scaffolded features are still mostly UI over an empty backend.

### Key Decisions Made
- **Scope:** Multi-user capable architecture from start (but single-user MVP)
- **Platforms:** Both web (Next.js + React + Supabase) AND native macOS (Swift/SwiftUI)
- **AI Approach:** Local/free first (Whisper.cpp for transcription, Ollama for summarization)
- **Audio Capture:** Meeting bot that joins as participant (Zoom/Teams/Google Meet)
- **MVP Features:** Full Circleback core - transcription + speaker diarization + notes + action items + search
- **Memory System:** Markdown-based with index.json + git history for persistence across sessions
- **Distribution:** public repo, ad-hoc signed universal `.app` on GitHub
  Releases, `curl | bash` installer (see decisions §8-§11)
- **Native credentials:** resolved at runtime, never baked into source

### Active Work
- Supabase schema: **no migrations exist yet**. The web app already queries a
  `search_vector` column and a `search_meetings_semantic` RPC that are not
  defined anywhere.
- Vercel env vars are unset, so the live site cannot talk to Supabase.
- Feature work on top of the scaffolding (transcription pipeline end to end).

### Architecture Overview
```
┌─────────────────────────────────────────────────────────────┐
│                        Loopback                              │
├──────────────────┬──────────────────────────────────────────┤
│   Web App        │   Native macOS App                       │
│   (Next.js)      │   (Swift/SwiftUI)                        │
├──────────────────┼──────────────────────────────────────────┤
│                  │                                          │
│   ┌──────────────┴──────────────┐                           │
│   │      Supabase Backend       │                           │
│   │  (Auth, DB, Realtime,       │                           │
│   │   Storage, Edge Functions)  │                           │
│   └──────────────┬──────────────┘                           │
│                  │                                          │
│   ┌──────────────┴──────────────┐                           │
│   │      Local AI Pipeline      │                           │
│   │  (Whisper.cpp + Ollama)     │                           │
│   └──────────────┬──────────────┘                           │
│                  │                                          │
│   ┌──────────────┴──────────────┐                           │
│   │    Meeting Bot Service      │                           │
│   │  (Zoom/Teams/Meet bots)     │                           │
│   └─────────────────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

### Tech Stack
- **Frontend (Web):** Next.js 14+ (App Router), React 18, TypeScript, Tailwind CSS, shadcn/ui
- **Frontend (Native):** Swift 5.9+, SwiftUI, SwiftData, macOS 14+
- **Backend:** Supabase (PostgreSQL, Auth, Realtime, Storage, Edge Functions)
- **AI/ML:** Whisper.cpp (transcription), Ollama (LLM for summarization/notes), pyannote.audio (speaker diarization)
- **Infrastructure:** GitHub Actions (CI/CD), Vercel (web), TestFlight/App Store (native)

### Important Files
- **Design Doc:** docs/plans/2025-08-20-loopback-design.md
- **Implementation Plan:** docs/plans/2025-08-20-loopback-implementation.md
- **Release Pipeline:** docs/architecture/release-pipeline.md
- **Key Decisions:** docs/memory/key-decisions.md
- **Latest Heartbeat:** docs/heartbeat/2026-08-21-session-3.md
- **API Spec:** docs/architecture/api-spec.md (to be created)

### Commands
```bash
# Start web dev server
cd web && npm run dev

# Build and run the native app (no Xcode needed)
./scripts/build-app.sh && open dist/Loopback.app

# Build web
cd web && npm run build && npm run lint

# Cut a macOS release (CI builds and publishes it)
git tag v0.2.0 && git push origin v0.2.0

# Install the released app the way a user would
curl -fsSL https://raw.githubusercontent.com/sicparvisventures/loopback/main/scripts/install.sh | bash
```

Note: there is no test suite yet, on either side.

### Known Issues / Blockers
- **Vercel env vars unset** — build is green, runtime Supabase calls fail
- **No Supabase migrations** — the schema the apps assume does not exist
- **Not notarised** — browser downloads hit Gatekeeper; needs a paid Apple
  Developer ID. The `curl` installer avoids it.
- **Ad-hoc signature changes per build** — macOS re-prompts for Screen
  Recording permission after every update
- Meeting bot implementation requires platform-specific APIs (Zoom SDK, Teams bot framework, Google Meet API)
- Speaker diarization with pyannote.audio requires HF token and GPU acceleration for speed
- Supabase free tier limits (500MB DB, 2GB bandwidth, 50MB file storage)

### Next Session Should
- Add Supabase env vars in Vercel and verify login on the live site
- Write the Supabase migrations (meetings, transcript segments, action items,
  speakers, `search_vector`, the `search_meetings_semantic` RPC, RLS policies)
- Wire the transcription pipeline end to end: record -> whisper.cpp -> notes
- Wire up `subscribeToMeetings`, which is implemented but never called
- Consider notarisation if the app goes to people outside the team

---
*Load this file at session start to restore context instantly*