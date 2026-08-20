# Loopback Design Document

**Date:** 2025-08-20
**Version:** 1.0.0
**Status:** Draft
**Author:** Dietmar (with opencode assistance)

---

## 1. Executive Summary

Loopback is a Circleback.ai clone - an AI-powered meeting assistant that automatically captures, transcribes, summarizes, and organizes meeting content. Built with a local-first AI approach (Whisper.cpp + Ollama) for privacy and cost-effectiveness, with dual-platform support: a web application (Next.js + Supabase) and a native macOS app (Swift/SwiftUI).

**Core Value Proposition:** "Never miss a detail. Search every conversation. Turn meetings into action."

---

## 2. Product Requirements

### 2.1 Target Users
- **Primary:** Individual professionals (developers, PMs, consultants, executives)
- **Secondary:** Small teams (2-10 people) sharing meeting knowledge
- **Future:** Enterprise with admin controls, compliance, SSO

### 2.2 Core Features (MVP)

| Feature | Description | Priority |
|---------|-------------|----------|
| Meeting Bot | Joins Zoom/Teams/Meet as participant, records audio | P0 |
| Transcription | Real-time + post-meeting, 100+ languages | P0 |
| Speaker Diarization | Identify and label speakers by name | P0 |
| Structured Notes | AI-generated organized notes with sections | P0 |
| Action Items | Extract tasks with assignees, due dates | P0 |
| Search | Full-text + semantic search across all meetings | P0 |
| Meeting History | List, filter, browse past meetings | P0 |
| Export/Share | PDF, Markdown, Notion, Linear, Slack | P1 |

### 2.3 Non-Functional Requirements
- **Privacy:** Audio/transcripts never leave user's infrastructure without consent
- **Latency:** Transcription < 30s after meeting ends; notes < 60s
- **Accuracy:** >95% WER for clear English; >90% for accented/technical
- **Availability:** 99.9% for web; native works fully offline
- **Scalability:** Support 1000+ meetings/user, 100+ concurrent users

---

## 3. System Architecture

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              LOOPBACK SYSTEM                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                  │
│  │  Web App     │    │  Native App  │    │  Meeting Bot │                  │
│  │  (Next.js)   │    │  (SwiftUI)   │    │  (Python)    │                  │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘                  │
│         │                   │                   │                          │
│         └───────────────────┼───────────────────┘                          │
│                             ▼                                              │
│                    ┌──────────────────┐                                   │
│                    │   Supabase       │                                   │
│                    │   (PostgreSQL +  │                                   │
│                    │    Auth + RT +   │                                   │
│                    │    Storage)      │                                   │
│                    └────────┬─────────┘                                   │
│                             │                                            │
│         ┌───────────────────┼───────────────────┐                        │
│         ▼                   ▼                   ▼                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                  │
│  │  Whisper.cpp│    │   Ollama    │    │  pyannote.  │                  │
│  │  (Transcribe)│    │  (Summarize)│    │  (Diarize)  │                  │
│  └─────────────┘    └─────────────┘    └─────────────┘                  │
│         │                   │                   │                        │
│         └───────────────────┼───────────────────┘                        │
│                             ▼                                              │
│                    ┌──────────────────┐                                   │
│                    │  Processing      │                                   │
│                    │  Pipeline        │                                   │
│                    │  (Edge Functions)│                                   │
│                    └──────────────────┘                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Component Details

#### 3.2.1 Meeting Bot Service (Python)
- **Purpose:** Join meetings as a participant, capture audio streams
- **Platforms:** Zoom (Meeting SDK), Teams (Bot Framework), Google Meet (Pueteer/Playwright)
- **Architecture:** One bot process per meeting; streams audio to processing pipeline
- **Deployment:** Railway/Render/Fly.io for cloud; can run locally for dev

#### 3.2.2 Processing Pipeline (Supabase Edge Functions)
- **Trigger:** Meeting ends → webhook from bot
- **Steps:**
  1. Download audio from bot storage
  2. Transcribe with Whisper.cpp (local binary or WASM)
  3. Diarize with pyannote.audio (speaker segments)
  4. Align transcription + diarization → labeled transcript
  5. Generate notes/action items with Ollama (Llama 3.1 / Mistral)
  6. Create embeddings for semantic search (nomic-embed-text via Ollama)
  7. Store all in Supabase
  8. Notify user (email, push, in-app)

#### 3.2.3 Web Application (Next.js 14 + Supabase)
- **Auth:** Supabase Auth (email/password, OAuth: Google, GitHub, Microsoft)
- **UI:** Tailwind CSS + shadcn/ui + Radix UI
- **Real-time:** Supabase Realtime for live meeting status, collaborative notes
- **Search:** Full-text (PostgreSQL tsvector) + Semantic (pgvector)

#### 3.2.4 Native macOS App (SwiftUI + SwiftData)
- **Offline-first:** Local SwiftData cache, syncs to Supabase when online
- **Menu bar app:** Quick access to recent meetings, start recording
- **System audio capture:** ScreenCaptureKit for loopback recording (alternative to bot)
- **Native integrations:** Calendar (EventKit), Shortcuts, Spotlight

### 3.3 Data Flow

```
Meeting Starts
     │
     ▼
┌─────────────┐
│ Meeting Bot │◄── Calendar integration (auto-join)
│  Joins      │
└──────┬──────┘
       │ Audio stream
       ▼
┌─────────────┐     Meeting Ends      ┌──────────────────┐
│ Bot records │ ────────────────────► │ Webhook to       │
│ audio to    │                       │ Supabase Edge    │
│ temp storage│                       │ Function         │
└─────────────┘                       └────────┬─────────┘
                                                │
                    ┌───────────────────────────┼───────────────────────────┐
                    ▼                           ▼                           ▼
           ┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
           │ Whisper.cpp     │          │ pyannote.audio  │          │ Ollama          │
           │ Transcribe      │          │ Diarize         │          │ Summarize       │
           └────────┬────────┘          └────────┬────────┘          └────────┬────────┘
                    │                           │                           │
                    └───────────────────────────┼───────────────────────────┘
                                                ▼
                                   ┌─────────────────────────┐
                                   │ Merge: Transcript +     │
                                   │ Speaker Labels          │
                                   └───────────┬─────────────┘
                                               ▼
                                   ┌─────────────────────────┐
                                   │ Ollama: Generate Notes  │
                                   │ + Action Items          │
                                   └───────────┬─────────────┘
                                               ▼
                                   ┌─────────────────────────┐
                                   │ Generate Embeddings     │
                                   │ (nomic-embed-text)      │
                                   └───────────┬─────────────┘
                                               ▼
                                   ┌─────────────────────────┐
                                   │ Store in Supabase       │
                                   │ (meetings, segments,    │
                                   │  notes, embeddings)     │
                                   └───────────┬─────────────┘
                                               ▼
                                   ┌─────────────────────────┐
                                   │ Notify User             │
                                   │ (Realtime, Email, Push) │
                                   └─────────────────────────┘
```

---

## 4. Database Schema (Supabase/PostgreSQL)

```sql
-- Users (Supabase Auth handles this, but we extend with profiles)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT,
  avatar_url TEXT,
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Meetings
CREATE TABLE meetings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  title TEXT NOT NULL,
  platform TEXT NOT NULL, -- 'zoom', 'teams', 'meet', 'local', 'manual'
  platform_meeting_id TEXT,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  status TEXT DEFAULT 'processing', -- 'processing', 'completed', 'failed'
  language TEXT DEFAULT 'en',
  audio_url TEXT,
  transcript_text TEXT,
  summary TEXT,
  notes_md TEXT, -- Full structured notes in markdown
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transcript Segments (with speaker labels)
CREATE TABLE transcript_segments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  speaker_id TEXT NOT NULL, -- e.g., 'SPEAKER_00', 'John'
  speaker_name TEXT, -- Resolved name if known
  start_ms INTEGER NOT NULL,
  end_ms INTEGER NOT NULL,
  text TEXT NOT NULL,
  confidence REAL,
  sequence INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Action Items
CREATE TABLE action_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  segment_id UUID REFERENCES transcript_segments(id),
  title TEXT NOT NULL,
  description TEXT,
  assignee_name TEXT,
  assignee_email TEXT,
  due_date DATE,
  status TEXT DEFAULT 'open', -- 'open', 'in_progress', 'done', 'cancelled'
  priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Speakers (resolved identities across meetings)
CREATE TABLE speakers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  name TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, email)
);

-- Meeting Speakers (link speakers to meetings)
CREATE TABLE meeting_speakers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  speaker_id UUID NOT NULL REFERENCES speakers(id) ON DELETE CASCADE,
  platform_speaker_id TEXT, -- e.g., 'SPEAKER_00' from diarization
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(meeting_id, platform_speaker_id)
);

-- Embeddings for semantic search (pgvector)
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE meeting_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
  segment_id UUID REFERENCES transcript_segments(id),
  content_type TEXT NOT NULL, -- 'transcript', 'summary', 'notes', 'action_item'
  content_text TEXT NOT NULL,
  embedding VECTOR(768), -- nomic-embed-text dimension
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_meetings_user_id ON meetings(user_id);
CREATE INDEX idx_meetings_started_at ON meetings(started_at DESC);
CREATE INDEX idx_meetings_status ON meetings(status);
CREATE INDEX idx_transcript_segments_meeting_id ON transcript_segments(meeting_id);
CREATE INDEX idx_action_items_meeting_id ON action_items(meeting_id);
CREATE INDEX idx_action_items_status ON action_items(status);
CREATE INDEX idx_meeting_embeddings_meeting_id ON meeting_embeddings(meeting_id);
CREATE INDEX idx_meeting_embeddings_embedding ON meeting_embeddings USING ivfflat (embedding vector_cosine_ops);

-- Full-text search
ALTER TABLE meetings ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(transcript_text, '') || ' ' || coalesce(summary, '') || ' ' || coalesce(notes_md, ''))) STORED;
CREATE INDEX idx_meetings_search ON meetings USING GIN(search_vector);

-- RLS Policies
ALTER TABLE meetings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can CRUD own meetings" ON meetings
  FOR ALL USING (auth.uid() = user_id);

-- Similar policies for other tables...
```

---

## 5. AI Pipeline Details

### 5.1 Transcription (Whisper.cpp)
- **Model:** `large-v3` (best accuracy) or `medium` (faster)
- **Format:** 16kHz mono WAV/MP3
- **Features:** Word-level timestamps, language detection, VAD
- **Deployment:** Compiled binary called from Edge Function; or WASM in browser for native app

### 5.2 Speaker Diarization (pyannote.audio)
- **Pipeline:** `pyannote/speaker-diarization-3.1`
- **Requires:** HuggingFace token (free), GPU recommended
- **Output:** Speaker segments with timestamps
- **Alignment:** Match whisper word timestamps to diarization segments

### 5.3 Summarization & Notes (Ollama)
- **Models:** 
  - `llama3.1:8b` (fast, good quality)
  - `mistral-nemo:12b` (better reasoning)
  - `qwen2.5:14b` (best for structured output)
- **Prompt Engineering:** Structured prompts for:
  - Executive summary (3-5 bullets)
  - Detailed notes by topic
  - Action items with assignees/dates
  - Key decisions
  - Follow-up questions

### 5.4 Embeddings (Ollama)
- **Model:** `nomic-embed-text` (768 dim, strong retrieval)
- **Chunking:** 500 tokens with 50 token overlap
- **Stored:** In pgvector for semantic search

---

## 6. API Specification

### 6.1 REST Endpoints (Supabase Edge Functions)

```
POST   /api/v1/meetings              # Create meeting (bot webhook)
GET    /api/v1/meetings              # List meetings (paginated, filtered)
GET    /api/v1/meetings/:id          # Get meeting details
GET    /api/v1/meetings/:id/transcript # Get full transcript
GET    /api/v1/meetings/:id/notes    # Get structured notes
GET    /api/v1/meetings/:id/actions  # Get action items
POST   /api/v1/meetings/:id/actions  # Create action item
PATCH  /api/v1/actions/:id           # Update action item
POST   /api/v1/search                # Search meetings (full-text + semantic)
GET    /api/v1/speakers              # List known speakers
POST   /api/v1/speakers              # Create/update speaker
POST   /api/v1/integrations/notion   # Export to Notion
POST   /api/v1/integrations/linear   # Export to Linear
POST   /api/v1/integrations/slack    # Send to Slack
```

### 6.2 Real-time Subscriptions
```
meetings:*          # All meeting updates for user
meetings:{id}       # Specific meeting updates
action_items:{id}   # Action item updates
```

---

## 7. Meeting Bot Implementation

### 7.1 Platform-Specific Approaches

| Platform | Method | Complexity | Audio Quality |
|----------|--------|------------|---------------|
| Zoom | Meeting SDK (Windows/macOS/Linux) | Medium | High (separate audio streams) |
| Teams | Bot Framework + Graph API | High | High |
| Google Meet | Puppeteer/Playwright (headless Chrome) | Medium | Medium (mixed audio) |

### 7.2 MVP Decision: Start with Zoom + Local Recording
- Zoom has best SDK support for bots
- Can use `zoom-meeting-sdk` npm package or native SDK
- For local recording alternative: ScreenCaptureKit (macOS) / WASAPI (Windows)

### 7.3 Bot Architecture
```python
# Simplified bot structure
class MeetingBot:
    def __init__(self, meeting_url, platform, meeting_id):
        self.meeting_url = meeting_url
        self.platform = platform
        self.meeting_id = meeting_id
        self.audio_buffer = []
        
    async def join(self):
        # Platform-specific join logic
        pass
    
    async def on_audio_received(self, participant_id, audio_chunk):
        # Buffer audio with participant ID for diarization
        self.audio_buffer.append({
            'participant_id': participant_id,
            'timestamp': time.time(),
            'audio': audio_chunk
        })
    
    async def leave(self):
        # Save audio, upload to Supabase Storage, trigger webhook
        pass
```

---

## 8. Frontend Architecture

### 8.1 Web App (Next.js 14 App Router)

```
web/
├── app/
│   ├── (auth)/
│   │   ├── login/
│   │   └── signup/
│   ├── (dashboard)/
│   │   ├── meetings/
│   │   │   ├── page.tsx           # Meeting list
│   │   │   ├── [id]/
│   │   │   │   ├── page.tsx       # Meeting detail
│   │   │   │   ├── transcript/
│   │   │   │   ├── notes/
│   │   │   │   └── actions/
│   │   ├── search/
│   │   ├── settings/
│   │   └── layout.tsx
│   ├── api/
│   │   └── webhooks/
│   └── layout.tsx
├── components/
│   ├── ui/              # shadcn/ui components
│   ├── meetings/
│   ├── transcript/
│   ├── notes/
│   └── search/
├── lib/
│   ├── supabase/
│   ├── utils/
│   └── hooks/
└── types/
```

### 8.2 Native App (SwiftUI + SwiftData)

```
native/Loopback/
├── LoopbackApp.swift
├── Models/
│   ├── Meeting.swift
│   ├── TranscriptSegment.swift
│   ├── ActionItem.swift
│   └── Speaker.swift
├── Views/
│   ├── MeetingListView.swift
│   ├── MeetingDetailView.swift
│   ├── TranscriptView.swift
│   ├── NotesView.swift
│   ├── ActionItemsView.swift
│   └── SearchView.swift
├── Services/
│   ├── SupabaseService.swift
│   ├── AudioRecorder.swift      # ScreenCaptureKit
│   ├── TranscriptionService.swift
│   └── SyncService.swift
├── ViewModels/
│   └── ...
└── Resources/
```

---

## 9. Security & Privacy

### 9.1 Data Protection
- **Encryption at rest:** Supabase handles (AES-256)
- **Encryption in transit:** TLS 1.3 everywhere
- **Audio processing:** Local-first option (Whisper.cpp on device)
- **No training:** Explicit policy - user data never used for model training

### 9.2 Access Control
- Row Level Security on all tables
- JWT-based auth with Supabase
- API keys for integrations (scoped permissions)

### 9.3 Compliance
- GDPR: Right to deletion, data portability
- SOC 2 Type II (future)
- HIPAA: BAA with Supabase (enterprise tier)

---

## 10. Deployment & Operations

### 10.1 Environments
- **Development:** Local (Docker Compose for Supabase, Ollama, Whisper)
- **Staging:** Vercel Preview + Supabase staging project
- **Production:** Vercel + Supabase Pro + Railway (bots)

### 10.2 CI/CD (GitHub Actions)
```yaml
# .github/workflows/ci.yml
- Lint (ESLint, SwiftLint)
- Typecheck (tsc, swiftc)
- Unit tests (Vitest, XCTest)
- E2E tests (Playwright)
- Build web + native
- Deploy preview (Vercel)
- Deploy production (on tag)
```

### 10.3 Monitoring
- **Supabase:** Built-in logs, metrics
- **Vercel:** Analytics, speed insights
- **Sentry:** Error tracking (web + native)
- **PostHog:** Product analytics (self-hosted option)

---

## 11. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- [ ] Persistent memory system ✓
- [ ] Design doc ✓
- [ ] Next.js + Supabase scaffold
- [ ] Swift macOS scaffold
- [ ] Database schema + migrations
- [ ] Auth flow (web + native)
- [ ] Basic meeting CRUD

### Phase 2: AI Pipeline (Weeks 3-4)
- [ ] Whisper.cpp integration (local binary)
- [ ] Ollama integration (summarization)
- [ ] pyannote.audio diarization
- [ ] Processing pipeline (Edge Functions)
- [ ] Embeddings + semantic search
- [ ] End-to-end test with sample audio

### Phase 3: Meeting Bot (Weeks 5-6)
- [ ] Zoom bot prototype
- [ ] Audio capture + upload
- [ ] Webhook integration
- [ ] Calendar integration (auto-join)
- [ ] Teams/Meet bots (parallel)

### Phase 4: Polish & Launch (Weeks 7-8)
- [ ] Web UI: Meeting list, detail, transcript, notes, actions
- [ ] Native UI: Equivalent views + menu bar
- [ ] Search (full-text + semantic)
- [ ] Export integrations (Notion, Linear, Slack)
- [ ] Settings, billing (Stripe)
- [ ] Documentation, landing page
- [ ] Beta launch

---

## 12. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Meeting bot reliability | High | High | Start with local recording fallback; multiple platform support |
| Diarization accuracy | Medium | High | Allow manual speaker correction; learn from corrections |
| Local AI performance | Medium | Medium | Offer cloud fallback (Groq, OpenAI) as BYOK option |
| Supabase costs at scale | Low | Medium | Monitor usage; optimize queries; consider self-hosted |
| Platform API changes | Medium | Medium | Abstract bot interface; maintain adapters |

---

## 13. Success Metrics

- **Activation:** % users who complete first meeting within 7 days
- **Retention:** Weekly active users / Monthly active users > 40%
- **Accuracy:** User-rated transcript quality > 4.5/5
- **Speed:** Median processing time < 60 seconds
- **Engagement:** Average meetings/user/week > 3

---

## 14. Appendix

### 14.1 Related Documents
- `docs/bootstrap/loopback-bootstrap.md` - Project context
- `docs/templates/*` - Document templates
- `docs/architecture/api-spec.md` - Detailed API spec (to be created)
- `docs/plans/2025-08-20-loopback-implementation.md` - Implementation plan (to be created)

### 14.2 References
- Circleback.ai - Product reference
- Whisper.cpp - https://github.com/ggerganov/whisper.cpp
- Ollama - https://ollama.ai
- pyannote.audio - https://github.com/pyannote/pyannote-audio
- Supabase - https://supabase.com
- Zoom Meeting SDK - https://marketplace.zoom.us/docs/sdk/native-sdks/