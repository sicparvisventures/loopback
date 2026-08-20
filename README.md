# Loopback - AI Meeting Notes

A Circleback.ai clone built with local-first AI, featuring a web app (Next.js + Supabase) and native macOS app (SwiftUI + SwiftData).

## 🎯 Features

- **Automatic Transcription** - Real-time with Whisper.cpp (95%+ accuracy, 100+ languages)
- **Speaker Diarization** - Identifies who said what (pyannote.audio)
- **Structured Notes** - AI-generated summaries, key decisions, topics
- **Action Items** - Extracted with assignees, due dates, priorities
- **Search** - Full-text + semantic search across all meetings
- **Meeting Bot** - Joins Zoom, Teams, Google Meet automatically
- **Privacy-First** - Local AI processing, your data never leaves your infrastructure
- **Dual Platform** - Web app + native macOS app with seamless sync

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Loopback                              │
├─────────────────────────────────────────────────────────────┤
│  Web App (Next.js)    │  Native macOS (SwiftUI)             │
├───────────────────────┼─────────────────────────────────────┤
│                       │                                      │
│     ┌─────────────────┴─────────────────┐                   │
│     │         Supabase Backend          │                   │
│     │  (PostgreSQL + Auth + Realtime +  │                   │
│     │   Storage + Edge Functions)       │                   │
│     └─────────────────┬─────────────────┘                   │
│                       │                                      │
│     ┌─────────────────┼─────────────────┐                   │
│     │   Local AI Pipeline (Edge/Device)│                   │
│     │  • Whisper.cpp (Transcription)   │                   │
│     │  • Ollama (LLM + Embeddings)     │                   │
│     │  • pyannote.audio (Diarization)  │                   │
│     └──────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
loopback/
├── docs/                      # Persistent memory system
│   ├── bootstrap/             # Project context for session restore
│   ├── heartbeat/             # Session continuity logs
│   ├── plans/                 # Design & implementation plans
│   ├── templates/             # Document templates
│   └── index.json             # Document index
├── web/                       # Next.js 14 Web App
│   ├── src/
│   │   ├── app/               # App Router pages
│   │   ├── components/        # React components
│   │   ├── lib/               # Utilities & Supabase clients
│   │   └── types/             # TypeScript types
│   └── package.json
├── native/                    # Swift macOS App
│   └── Loopback/
│       ├── LoopbackApp.swift
│       ├── Models/
│       ├── Views/
│       ├── Services/
│       └── Resources/
└── setup-ai.sh               # AI pipeline installer
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- macOS 14+ (for native app)
- Supabase account
- Homebrew (for AI dependencies)

### 1. Install AI Dependencies
```bash
./setup-ai.sh
```

### 2. Configure Supabase
```bash
cp web/.env.example web/.env.local
# Edit web/.env.local with your Supabase credentials
```

### 3. Run Database Migrations
```bash
cd web
npx supabase db push
```

### 4. Start Web App
```bash
cd web
npm run dev
# Open http://localhost:3000
```

### 5. Build Native App
1. Open `native/Loopback/Loopback.xcodeproj` in Xcode
2. Add Supabase Swift package dependency
3. Configure entitlements for screen recording
4. Build and run (⌘R)

## 🔧 Configuration

### Environment Variables (web/.env.local)
```env
NEXT_PUBLIC_SUPABASE_URL=your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### AI Models
- **Transcription**: Whisper.cpp (large-v3, medium, tiny)
- **Summarization**: Ollama (llama3.1:8b, mistral-nemo:12b)
- **Embeddings**: Ollama (nomic-embed-text)
- **Diarization**: pyannote.audio 3.1 (requires HF token)

### Meeting Bot Platforms
- **Zoom**: Meeting SDK (best quality)
- **Teams**: Bot Framework + Graph API
- **Google Meet**: Puppeteer automation

## 📚 Documentation

- [Design Document](docs/plans/2025-08-20-loopback-design.md)
- [Implementation Plan](docs/plans/2025-08-20-loopback-implementation.md)
- [Native App Setup](native/Loopback/NATIVE_SETUP.md)
- [API Specification](docs/architecture/api-spec.md) *(to be created)*

## 🧠 Persistent Memory System

The `docs/` folder contains a markdown-based memory system that persists context across sessions:

- **bootstrap/** - Project context for instant session restore
- **heartbeat/** - Session logs with decisions and progress
- **plans/** - Design docs and implementation plans
- **templates/** - Reusable templates for analysis, sparring, implementation
- **index.json** - Searchable index of all documents

## 🛠 Development

### Web App
```bash
cd web
npm run dev        # Development server
npm run build      # Production build
npm run lint       # ESLint
npm run typecheck  # TypeScript check
```

### Native App
```bash
cd native/Loopback
swift build        # Debug build
swift build -c release  # Release build
swift test         # Run tests
```

### Database
```bash
cd web
npx supabase migration new name  # Create migration
npx supabase db push             # Apply migrations
npx supabase db reset            # Reset local DB
```

## 🧪 Testing

- **Web**: Vitest + Playwright
- **Native**: XCTest
- **AI Pipeline**: Sample audio files in `tests/fixtures/`

## 📦 Deployment

### Web (Vercel)
1. Connect GitHub repo to Vercel
2. Add environment variables
3. Deploy

### Native (Mac App Store / Direct)
1. Archive in Xcode
2. Notarize with Apple
3. Distribute via TestFlight or direct download

### Meeting Bots
Deploy to Railway/Render/Fly.io for 24/7 availability

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Follow the persistent memory workflow (update docs/heartbeat)
4. Submit PR with design doc reference

## 📄 License

MIT License - See LICENSE file

## 🙏 Acknowledgments

- [Circleback.ai](https://circleback.ai) - Product inspiration
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp) - Local transcription
- [Ollama](https://ollama.ai) - Local LLM runtime
- [Supabase](https://supabase.com) - Backend platform
- [shadcn/ui](https://ui.shadcn.com) - Web UI components