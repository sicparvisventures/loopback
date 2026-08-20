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

## ⬇️ Installing the macOS app

**One-liner** — recommended, and the only route with no Gatekeeper prompt
(files fetched with `curl` are not quarantined):

```bash
curl -fsSL https://raw.githubusercontent.com/sicparvisventures/loopback/main/scripts/install.sh | bash
```

This installs the latest release to `/Applications` (or `~/Applications` when
`/Applications` is not writable — it never asks for `sudo`). Pin a version with
`LOOPBACK_VERSION=v0.1.0`.

**Manual download** — grab `Loopback-<version>-macos-universal.zip` from the
[Releases page](https://github.com/sicparvisventures/loopback/releases/latest),
unzip, and drag `Loopback.app` into Applications. Builds are ad-hoc signed but
**not notarised**, so macOS blocks the first launch of a browser download.
Either right-click the app and choose **Open**, or clear the quarantine flag:

```bash
xattr -dr com.apple.quarantine /Applications/Loopback.app
```

Requires **macOS 14 (Sonoma) or later**. Universal binary — one download for
Apple Silicon and Intel. Verify against the release's `SHA256SUMS.txt`:

```bash
shasum -a 256 -c SHA256SUMS.txt
```

### First run

1. Grant **Screen Recording** in System Settings → Privacy & Security, then
   restart Loopback. Without it, system audio cannot be captured.
2. Open **Settings → Supabase Connection** and enter your project URL and anon
   key. Until then Loopback runs entirely locally on SwiftData; nothing syncs.

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
├── scripts/                   # Release tooling
│   ├── build-app.sh           # Assemble universal Loopback.app
│   └── install.sh             # curl | bash installer
├── .github/workflows/         # CI + macOS release automation
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

Or skip Xcode entirely:

```bash
./scripts/build-app.sh && open dist/Loopback.app
```

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
```

`next build` type-checks the whole app, so there is no separate typecheck
script.

### Native App
```bash
cd native/Loopback
swift build             # Debug build
swift build -c release  # Release build
```

Sources live in `native/Loopback/Loopback/` (Xcode-style layout), which
`Package.swift` points the target at explicitly. There is no test target yet.
To produce a runnable app rather than a bare executable, use
`./scripts/build-app.sh`.

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

`main` deploys to production automatically. The Vercel project
(`reserve4you/loopback`) is linked to this repository with **Root Directory
`web`**, so every push to `main` builds and promotes; every pull request gets a
preview URL.

Set the runtime environment variables once, in Vercel → Settings → Environment
Variables (the build succeeds without them, but Supabase calls will fail at
runtime):

| Variable | Scope |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | Production, Preview, Development |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Production, Preview, Development |
| `SUPABASE_SERVICE_ROLE_KEY` | Production only |
| `NEXT_PUBLIC_APP_URL` | Production, Preview |

### Native (macOS)

Tag a version and CI builds and publishes the release:

```bash
git tag v0.1.0
git push origin v0.1.0
```

`.github/workflows/release-native.yml` builds a universal (Apple Silicon +
Intel) `Loopback.app`, ad-hoc signs it, and attaches the zip plus a
`SHA256SUMS.txt` to a GitHub Release. See [Installing](#-installing-the-macos-app).

To cut a build locally instead:

```bash
./scripts/build-app.sh 0.1.0      # -> dist/Loopback.app + dist/Loopback-0.1.0-macos-universal.zip
```

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