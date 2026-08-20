# Loopback - Bootstrap Context

## Project: Loopback
**Initialized:** 2025-08-20
**Version:** 0.1.0

## Quick Context for New Sessions

### What is this project?
A Circleback.ai clone for personal/team use - AI-powered meeting notes with transcription, speaker diarization, structured notes, action items, and search across all meetings. Built with local-first AI (Whisper.cpp + Ollama), webapp (Next.js + Supabase), and native macOS app (Swift/SwiftUI).

### Current Phase
**Research & Scaffolding** - Setting up persistent memory system, writing design doc, scaffolding project structure

### Key Decisions Made
- **Scope:** Multi-user capable architecture from start (but single-user MVP)
- **Platforms:** Both web (Next.js + React + Supabase) AND native macOS (Swift/SwiftUI)
- **AI Approach:** Local/free first (Whisper.cpp for transcription, Ollama for summarization)
- **Audio Capture:** Meeting bot that joins as participant (Zoom/Teams/Google Meet)
- **MVP Features:** Full Circleback core - transcription + speaker diarization + notes + action items + search
- **Memory System:** Markdown-based with index.json + git history for persistence across sessions

### Active Work
- Creating persistent memory system structure (docs/, templates, index.json)
- Writing design document for Loopback
- Scaffolding Next.js + Supabase webapp
- Scaffolding Swift macOS native app

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
- **Design Doc:** docs/plans/2025-08-20-loopback-design.md (to be created)
- **Implementation Plan:** docs/plans/2025-08-20-loopback-implementation.md (to be created)
- **API Spec:** docs/architecture/api-spec.md (to be created)

### Commands
```bash
# Start web dev server
cd web && npm run dev

# Start native app (Xcode)
open native/Loopback.xcodeproj

# Run tests
cd web && npm test
cd native && xcodebuild test -scheme Loopback

# Build web
cd web && npm run build

# Build native
cd native && xcodebuild -scheme Loopback -configuration Release
```

### Known Issues / Blockers
- Meeting bot implementation requires platform-specific APIs (Zoom SDK, Teams bot framework, Google Meet API)
- Speaker diarization with pyannote.audio requires HF token and GPU acceleration for speed
- Supabase free tier limits (500MB DB, 2GB bandwidth, 50MB file storage)

### Next Session Should
- Complete design document
- Scaffold Next.js project with Supabase integration
- Scaffold Swift macOS project with SwiftData
- Set up local AI pipeline (Whisper.cpp + Ollama)
- Create meeting bot prototype for one platform

---
*Load this file at session start to restore context instantly*