# Loopback Implementation Plan

**Date:** 2025-08-20
**Version:** 1.0.0
**Status:** Draft
**Based on:** docs/plans/2025-08-20-loopback-design.md

---

## Phase 1: Foundation (Weeks 1-2)

### Week 1: Project Setup & Scaffolding

#### Day 1-2: Web App Scaffold
- [ ] Initialize Next.js 14 project with TypeScript, Tailwind, ESLint, Prettier
- [ ] Configure Supabase client (browser + server)
- [ ] Set up authentication (Supabase Auth + OAuth providers)
- [ ] Create base layout with sidebar navigation
- [ ] Add shadcn/ui component library
- [ ] Configure environment variables

```bash
# Commands
npx create-next-app@latest web --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
cd web
npm install @supabase/supabase-js @supabase/ssr
npm install -D @types/node
npx shadcn-ui@latest init
```

#### Day 3-4: Database & Migrations
- [ ] Create Supabase project
- [ ] Run migration for all tables (see design doc schema)
- [ ] Enable RLS policies
- [ ] Create database types with `supabase gen types typescript`
- [ ] Set up local Supabase for development

```bash
# Commands
supabase init
supabase start
supabase db push
supabase gen types typescript --local > src/lib/database.types.ts
```

#### Day 5: Native App Scaffold
- [ ] Create Xcode project (SwiftUI, SwiftData, macOS 14+)
- [ ] Configure Supabase Swift SDK
- [ ] Set up SwiftData models matching database schema
- [ ] Create basic app structure (App, Views, Services, ViewModels)
- [ ] Add menu bar app configuration

```swift
// Package.swift dependencies
.package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
.package(url: "https://github.com/apple/swift-data", from: "1.0.0")
```

### Week 2: Core Features

#### Day 6-7: Meeting CRUD (Web + Native)
- [ ] Meeting list view (paginated, filterable)
- [ ] Meeting detail view
- [ ] Create meeting manually (title, platform, date)
- [ ] Delete meeting
- [ ] Real-time updates via Supabase Realtime

#### Day 8-9: Authentication & User Profile
- [ ] Login/Signup pages (web)
- [ ] Onboarding flow
- [ ] User settings page (timezone, display name, avatar)
- [ ] Native app auth flow

#### Day 10: CI/CD & Dev Environment
- [ ] GitHub Actions workflow (lint, typecheck, test, build)
- [ ] Vercel preview deployments
- [ ] Local development script (starts Supabase, Ollama, Whisper, Next.js)
- [ ] README with setup instructions

---

## Phase 2: AI Pipeline (Weeks 3-4)

### Week 3: Local AI Setup

#### Day 11-12: Whisper.cpp Integration
- [ ] Compile Whisper.cpp for macOS (Metal) and Linux
- [ ] Download models (large-v3, medium, tiny)
- [ ] Create CLI wrapper for transcription
- [ ] Test with sample audio files
- [ ] Benchmark: speed vs accuracy tradeoffs

```bash
# Whisper.cpp compile
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
make WHISPER_METAL=1
# Models
bash ./models/download-ggml-model.sh large-v3
```

#### Day 13-14: Ollama Setup
- [ ] Install Ollama locally
- [ ] Pull models: llama3.1:8b, mistral-nemo:12b, nomic-embed-text
- [ ] Create API wrapper for chat + embeddings
- [ ] Test prompt templates for notes generation

```bash
ollama pull llama3.1:8b
ollama pull mistral-nemo:12b
ollama pull nomic-embed-text
```

#### Day 15: pyannote.audio Diarization
- [ ] Set up Python environment with pyannote.audio
- [ ] Get HuggingFace token for pyannote/speaker-diarization-3.1
- [ ] Create diarization service
- [ ] Implement alignment with Whisper timestamps
- [ ] Test with multi-speaker audio

### Week 4: Processing Pipeline

#### Day 16-17: Supabase Edge Functions
- [ ] Create `process-meeting` Edge Function
- [ ] Implement pipeline steps:
  1. Download audio from Storage
  2. Run Whisper.cpp transcription
  3. Run pyannote diarization
  4. Align transcript + speakers
  5. Generate notes with Ollama
  6. Generate embeddings
  7. Store all in database
  8. Trigger realtime notification

#### Day 18-19: Pipeline Integration
- [ ] Webhook endpoint for meeting bot
- [ ] Audio upload to Supabase Storage
- [ ] Status tracking (processing → completed/failed)
- [ ] Error handling & retries
- [ ] Progress updates via Realtime

#### Day 20: Testing & Optimization
- [ ] End-to-end test with real meeting audio
- [ ] Optimize: parallel processing, caching
- [ ] Add fallback to cloud APIs (Groq Whisper, OpenAI)
- [ ] Document prompt templates

---

## Phase 3: Meeting Bot (Weeks 5-6)

### Week 5: Zoom Bot MVP

#### Day 21-22: Zoom Meeting SDK Setup
- [ ] Create Zoom Marketplace app (Meeting SDK)
- [ ] Configure OAuth + webhooks
- [ ] Set up bot user in Zoom account

#### Day 23-24: Bot Implementation
- [ ] Join meeting via SDK
- [ ] Capture raw audio per participant
- [ ] Handle meeting events (join, leave, end)
- [ ] Save audio locally during meeting

#### Day 25: Audio Processing & Upload
- [ ] Convert raw audio to WAV/MP3
- [ ] Upload to Supabase Storage
- [ ] Trigger processing webhook
- [ ] Clean up local files

### Week 6: Multi-Platform & Calendar

#### Day 26-27: Teams Bot (Parallel)
- [ ] Azure Bot registration
- [ ] Teams manifest + App Studio
- [ ] Graph API for meeting join
- [ ] Audio capture via Bot Framework

#### Day 28: Google Meet Bot (Parallel)
- [ ] Puppeteer/Playwright automation
- [ ] Join as guest, capture tab audio
- [ ] Handle Google auth

#### Day 29-30: Calendar Integration
- [ ] Google Calendar API (watch for meetings)
- [ ] Outlook/Exchange API
- [ ] Auto-join logic (match meeting URL → platform)
- [ ] User preferences (auto-join, ask first, manual)

---

## Phase 4: Polish & Launch (Weeks 7-8)

### Week 7: Web UI Polish

#### Day 31-32: Meeting Detail Views
- [ ] Transcript view with speaker colors, timestamps, search
- [ ] Notes view (rendered markdown, editable)
- [ ] Action items view (kanban/list, inline edit)
- [ ] Audio player with transcript sync

#### Day 33-34: Search & Discovery
- [ ] Full-text search page (PostgreSQL tsvector)
- [ ] Semantic search (pgvector + embeddings)
- [ ] Combined search with filters (date, speaker, platform)
- [ ] Search results highlighting

#### Day 35: Settings & Integrations
- [ ] Integrations page (Notion, Linear, Slack, Zapier)
- [ ] OAuth flows for each integration
- [ ] Export buttons (PDF, Markdown, JSON)
- [ ] Notification preferences

### Week 8: Native App & Launch Prep

#### Day 36-37: Native App Feature Parity
- [ ] Meeting list + detail views
- [ ] Transcript, notes, actions views
- [ ] Search (local + remote)
- [ ] Menu bar quick access
- [ ] ScreenCaptureKit for local recording (alternative to bot)

#### Day 38: Sync & Offline
- [ ] SwiftData → Supabase sync engine
- [ ] Conflict resolution
- [ ] Background sync
- [ ] Offline indicator

#### Day 39: Billing & Landing
- [ ] Stripe integration (subscription tiers)
- [ ] Landing page with demo
- [ ] Pricing page
- [ ] Terms/Privacy

#### Day 40: Launch
- [ ] Beta invite system
- [ ] Documentation site
- [ ] Analytics (PostHog)
- [ ] Error tracking (Sentry)
- [ ] Launch announcement

---

## Technical Debt & Future Work

### Post-Launch (Month 2-3)
- [ ] Speaker identification learning (user corrections → better diarization)
- [ ] Custom vocabulary per user/team
- [ ] Meeting templates (standup, retro, sales, interview)
- [ ] Team workspaces with shared meetings
- [ ] Mobile apps (iOS/Android via React Native or Capacitor)
- [ ] API for third-party developers
- [ ] MCP server for AI assistant integration

### Optimization
- [ ] WASM Whisper for browser-based transcription (native app)
- [ ] Streaming transcription (real-time during meeting)
- [ ] Smart chapters/topics detection
- [ ] Multi-language meeting support
- [ ] Vector search optimization (HNSW indexes)

---

## Resource Requirements

### Development
- **Mac** with Apple Silicon (for Whisper Metal, SwiftUI)
- **GPU** (optional but recommended for pyannote) - can use Colab/RunPod for dev
- **Supabase** Pro plan ($25/mo) for production
- **Vercel** Pro ($20/mo) for web hosting
- **Railway/Render** ($10-20/mo) for meeting bots

### API Keys Needed
- Supabase (URL, anon key, service role key)
- Zoom OAuth credentials
- Teams/Azure Bot credentials
- Google Cloud (Calendar, Meet)
- HuggingFace (pyannote token)
- Stripe (billing)
- PostHog, Sentry (monitoring)

---

## Definition of Done per Phase

### Phase 1 Complete When:
- [ ] Web app runs locally with auth + meeting CRUD
- [ ] Native app builds and runs with auth + meeting list
- [ ] Database schema deployed to Supabase
- [ ] CI/CD pipeline passes

### Phase 2 Complete When:
- [ ] Can transcribe 30min meeting < 60s locally
- [ ] Diarization identifies speakers > 90% accuracy
- [ ] Notes generated are coherent and structured
- [ ] Search returns relevant results

### Phase 3 Complete When:
- [ ] Bot joins Zoom meeting, records, uploads, triggers processing
- [ ] User sees completed meeting in app within 2 min of meeting end
- [ ] Calendar auto-join works for Zoom

### Phase 4 Complete When:
- [ ] Web + Native apps have feature parity for core flows
- [ ] Search works (full-text + semantic)
- [ ] At least 2 integrations functional
- [ ] Beta users can sign up and use end-to-end

---

## Risk Register

| ID | Risk | Mitigation | Owner |
|----|------|------------|-------|
| R1 | pyannote requires GPU | Use RunPod/Colab for dev; optimize for CPU inference | Dev |
| R2 | Zoom SDK complexity | Start with local recording fallback (ScreenCaptureKit) | Dev |
| R3 | Whisper.cpp compilation issues | Use pre-built binaries; Docker for consistency | Dev |
| R4 | Supabase Edge Function limits | Optimize payload size; use background jobs for heavy processing | Dev |
| R5 | Speaker diarization errors | Build manual correction UI; learn from corrections | Dev |

---

## Next Actions

1. **Immediate:** Scaffold Next.js project (`web/`) with Supabase
2. **Immediate:** Scaffold Swift project (`native/Loopback`) with SwiftData
3. **This Week:** Set up local Supabase + run migrations
4. **This Week:** Test Whisper.cpp + Ollama locally with sample audio

---

*Generated from design doc. Update as implementation progresses.*