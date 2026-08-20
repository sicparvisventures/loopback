# System Architecture Overview

**Date:** 2025-08-20
**Version:** 1.0.0

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            LOOPBACK SYSTEM                                   │
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

## Component Details

### 1. Web Application (Next.js 14)
- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS + shadcn/ui
- **State**: React Server Components + Client Components
- **Auth**: Supabase Auth (SSR with middleware)
- **Real-time**: Supabase Realtime subscriptions
- **Deployment**: Vercel

### 2. Native macOS App (SwiftUI)
- **Framework**: SwiftUI + SwiftData
- **Language**: Swift 5.9+
- **Minimum OS**: macOS 14 (Sonoma)
- **Persistence**: SwiftData (local) + Supabase sync
- **Menu Bar**: NSStatusItem for quick access
- **Audio**: ScreenCaptureKit for system audio
- **Deployment**: Xcode Archive → TestFlight / Mac App Store

### 3. Meeting Bot Service (Python)
- **Platforms**: Zoom SDK, Teams Bot Framework, Google Meet (Puppeteer)
- **Audio**: Raw PCM per participant
- **Deployment**: Railway/Render/Fly.io (always-on)
- **Webhook**: POST to Supabase Edge Function on meeting end

### 4. Supabase Backend
- **Database**: PostgreSQL with pgvector extension
- **Auth**: Email/password + OAuth (Google, GitHub, Microsoft)
- **Real-time**: WebSocket subscriptions
- **Storage**: S3-compatible for audio files
- **Edge Functions**: Deno runtime for AI pipeline
- **Migrations**: Version-controlled SQL

### 5. AI Pipeline (Local-First)
```
Audio File (WAV/MP3)
        │
        ▼
┌───────────────────┐
│   Whisper.cpp     │ ──► Transcript + Word Timestamps
│   (large-v3)      │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│   pyannote.audio  │ ──► Speaker Segments
│   (3.1)           │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│   Alignment       │ ──► Labeled Transcript
│   (Merge)         │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│   Ollama LLM      │ ──► Notes + Actions + Summary
│   (llama3.1:8b)   │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│   Ollama Embed    │ ──► Vector Embeddings
│   (nomic-embed)   │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│   Supabase Store  │ ──► Persistent + Searchable
│   (pgvector)      │
└───────────────────┘
```

## Data Flow

### Meeting Creation (Manual)
```
User → Web/Native App → Supabase (meetings table) → UI Update
```

### Meeting Bot Flow
```
Calendar Event → Bot Service → Join Meeting → Record Audio
                                                    │
                                                    ▼
                                            Upload to Storage
                                                    │
                                                    ▼
                                            Webhook → Edge Function
                                                    │
                                                    ▼
                                            AI Pipeline (Async)
                                                    │
                                                    ▼
                                            Update Meeting Record
                                                    │
                                                    ▼
                                            Realtime → UI Update
```

### Search Flow
```
User Query → Full-text (tsvector) + Semantic (pgvector)
                    │
                    ▼
            Ranked Results → UI
```

## Security Model

- **Row Level Security**: All tables have RLS policies
- **Auth**: JWT-based with Supabase
- **Storage**: Signed URLs for audio access
- **API**: Service role key for server-side only
- **Encryption**: TLS 1.3 in transit, AES-256 at rest

## Scalability Considerations

- **Edge Functions**: Stateless, auto-scaling
- **Database**: Connection pooling (PgBouncer)
- **Real-time**: Horizontal scaling with Redis
- **Storage**: CDN for audio delivery
- **AI Pipeline**: Queue-based (Supabase pg_cron or external)

## Monitoring & Observability

- **Logs**: Supabase Dashboard + Vercel Logs
- **Errors**: Sentry (Web + Native)
- **Analytics**: PostHog (self-hosted option)
- **Performance**: Vercel Speed Insights
- **Database**: Supabase Metrics