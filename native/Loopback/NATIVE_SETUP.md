# Loopback Native macOS App - Setup Guide

## Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+
- Swift 5.9+
- Homebrew (for dependencies)

## Installation

### 1. Install Dependencies

```bash
# Install whisper.cpp
brew install whisper.cpp

# Install Ollama (for local LLM)
brew install ollama

# Pull required models
ollama pull llama3.1:8b
ollama pull mistral-nemo:12b
ollama pull nomic-embed-text
```

### 2. Create Xcode Project

1. Open Xcode
2. Create new project: **macOS → App**
3. Configure:
   - **Product Name**: Loopback
   - **Language**: Swift
   - **Interface**: SwiftUI
   - **Use Swift Data**: ✓ Yes
   - **Storage**: SwiftData (local) + Supabase (cloud)
4. Save to: `/Users/dietmar/loopback/native/Loopback/`

### 3. Add Package Dependencies

1. File → Add Package Dependencies
2. Enter: `https://github.com/supabase/supabase-swift`
3. Version: `2.0.0` or later
4. Add to target: Loopback

### 4. Configure Project Settings

#### Build Settings
- **Swift Language Version**: Swift 5
- **Deployment Target**: macOS 14.0
- **Enable Sandbox**: NO (required for ScreenCaptureKit)

#### Info.plist
The `Info.plist` is already configured with required permissions:
- Screen recording (NSScreenCaptureUsageDescription)
- Microphone (NSMicrophoneUsageDescription)
- Camera (NSCameraUsageDescription)
- Calendar (NSCalendarsUsageDescription)
- Contacts (NSContactsUsageDescription)
- Reminders (NSRemindersUsageDescription)

#### Entitlements
Create `Loopback.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.device.microphone</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

### 5. Configure Supabase

1. Create Supabase project at https://supabase.com
2. Run database migrations (see web app setup)
3. Update `SupabaseService.swift` with your credentials:
   ```swift
   let supabaseURL = URL(string: "YOUR_SUPABASE_URL")!
   let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
   ```

### 6. Build and Run

1. Select Loopback target
2. Press ⌘R to build and run
3. Grant screen recording permission when prompted
4. Sign in with Supabase account

## Project Structure

```
Loopback/
├── LoopbackApp.swift           # App entry point
├── Models/
│   └── Meeting.swift           # SwiftData models
├── Views/
│   ├── ContentView.swift       # Main window
│   ├── MeetingListView.swift   # Meeting list
│   ├── MeetingDetailView.swift # Meeting detail
│   ├── CalendarView.swift      # Calendar
│   ├── ActionsView.swift       # Action items (Kanban)
│   ├── SearchView.swift        # Search
│   ├── SettingsView.swift      # Settings
│   ├── NewMeetingView.swift    # Create meeting
│   └── MenuBarView.swift       # Menu bar extra
├── Services/
│   ├── SupabaseService.swift   # Supabase integration
│   ├── AudioRecorder.swift     # ScreenCaptureKit recording
│   └── TranscriptionService.swift # Whisper.cpp integration
└── Resources/
    ├── Info.plist
    └── Loopback.entitlements
```

## Key Features Implemented

### Audio Recording
- Uses `ScreenCaptureKit` for system audio capture
- Records to WAV file (16kHz, mono for Whisper)
- Real-time audio level visualization

### Transcription Pipeline
- Integrates with `whisper.cpp` via command line
- Supports word-level timestamps
- JSON output parsing for segments

### Data Layer
- **SwiftData** for local persistence (offline-first)
- **Supabase** for cloud sync and real-time updates
- Automatic sync when online

### UI Components
- Native macOS design with SwiftUI
- Menu bar extra for quick access
- Keyboard shortcuts support
- Dark/Light mode support

## Development

### Running Tests
```bash
swift test
```

### Building for Release
```bash
swift build -c release
# Or in Xcode: Product → Archive
```

### Debugging Tips
- Use `Console.app` to view logs
- Screen recording permission: System Settings → Privacy & Security → Screen Recording
- Check `~/Library/Containers/com.loopback.app/Data/Documents/` for recordings

## Troubleshooting

### "Screen recording permission denied"
- Go to System Settings → Privacy & Security → Screen Recording
- Enable Loopback
- Restart the app

### "whisper.cpp not found"
- Run: `brew install whisper.cpp`
- Check path in Settings: `/opt/homebrew/bin/whisper-cli`

### Build errors with Supabase
- Ensure package resolved: File → Packages → Resolve Package Versions
- Clean build folder: Product → Clean Build Folder

## Distribution

### Notarization
1. Archive in Xcode
2. Distribute App → Developer ID
3. Notarize with Apple
4. Export and distribute

### App Store
- Enable Sandbox (requires redesign for audio capture)
- Use App Store Connect

## Next Steps

- [ ] Add meeting bot integration (Zoom/Teams/Meet)
- [ ] Implement speaker diarization (pyannote.audio via Python bridge)
- [ ] Add Ollama integration for summarization
- [ ] Implement semantic search with pgvector
- [ ] Add keyboard shortcuts
- [ ] Implement drag & drop for audio files
- [ ] Add export to Notion/Linear/Slack