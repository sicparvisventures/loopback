# Native macOS App Scaffolding Log

**Date:** 2025-08-20
**Status:** Complete (Source files created, Xcode project setup documented)

## Summary
Created complete SwiftUI + SwiftData source code for native macOS app with menu bar extra, meeting management, and Supabase integration.

## Project Structure Created

```
native/Loopback/
├── LoopbackApp.swift
├── Models/
│   └── Meeting.swift
├── Views/
│   ├── ContentView.swift
│   ├── MeetingListView.swift
│   ├── MeetingDetailView.swift
│   ├── CalendarView.swift
│   ├── ActionsView.swift
│   ├── SearchView.swift
│   ├── SettingsView.swift
│   ├── NewMeetingView.swift
│   └── MenuBarView.swift
├── Services/
│   ├── SupabaseService.swift
│   ├── AudioRecorder.swift
│   └── TranscriptionService.swift
├── Resources/
│   ├── Info.plist
│   └── Loopback.entitlements (template)
├── Package.swift
├── Loopback.xcodeproj/ (placeholder)
└── NATIVE_SETUP.md
```

## Key Components

### Models (SwiftData)
- **Meeting** - Core meeting entity with relations
- **TranscriptSegment** - Speaker-labeled transcript pieces
- **ActionItem** - Extracted tasks with assignee, due date, status
- **Speaker** - Known speakers across meetings
- **MeetingSpeaker** - Join table for meeting-speaker mapping

### Views

#### ContentView
- NavigationSplitView with sidebar
- Menu bar extra integration
- Tab-based navigation (Meetings, Calendar, Actions, Search, Settings)

#### MeetingListView
- Searchable, filterable meeting list
- Status badges, platform icons
- Sort options (date, duration, title)
- Empty state with CTA

#### MeetingDetailView
- Header with meeting metadata
- Tabbed interface: Overview, Transcript, Notes, Actions
- Transcript with speaker labels and timestamps
- Markdown rendering for notes
- Action items with priority/status badges

#### CalendarView
- Month grid with meeting indicators
- Day selection with meeting list
- Navigation between months
- Today highlighting

#### ActionsView
- Kanban board (To Do / In Progress / Done)
- Drag-and-drop ready structure
- Priority color coding
- New action creation modal

#### SearchView
- Full-text + semantic search toggle
- Real-time results with context snippets
- Match type indicators (title, transcript, notes, actions)
- Highlighted search terms

#### SettingsView
- Account management (sign in/out)
- Theme selection (Light/Dark/System)
- Meeting behavior toggles
- AI model configuration
- Data export/clear

#### NewMeetingView
- Title, platform, date/time, duration
- Local recording with ScreenCaptureKit
- Real-time audio level meter
- Recording pause/stop controls

#### MenuBarView
- Quick access to recent meetings
- Recording status indicator
- New meeting / settings / quit
- Connection status

### Services

#### SupabaseService
- Singleton pattern with @MainActor
- Authentication (sign in/up/out, OAuth)
- Meeting CRUD operations
- Real-time subscriptions
- Audio upload to Supabase Storage
- Remote ↔ Local model conversion

#### AudioRecorder
- ScreenCaptureKit integration
- System audio capture (16kHz mono)
- Real-time audio level monitoring
- WAV file output
- Permission handling

#### TranscriptionService
- Whisper.cpp command-line integration
- Progress parsing from stderr
- JSON output parsing
- Multiple model support (tiny through large-v3)
- Error handling with descriptive messages

## Configuration Files

### Package.swift
- Swift Package Manager manifest
- Supabase Swift SDK dependency
- macOS 14 deployment target
- Strict concurrency enabled

### Info.plist
- App metadata (name, version, identifier)
- Privacy descriptions for:
  - Screen recording (NSScreenCaptureUsageDescription)
  - Microphone (NSMicrophoneUsageDescription)
  - Camera (NSCameraUsageDescription)
  - Calendar (NSCalendarsUsageDescription)
  - Contacts (NSContactsUsageDescription)
  - Reminders (NSRemindersUsageDescription)
  - Desktop/Documents folder access

### Entitlements Template
- Audio input permission
- Microphone permission
- Network client
- File read/write (user-selected, downloads)
- Apple Events automation

## Setup Documentation (NATIVE_SETUP.md)
- Prerequisites (Xcode, Homebrew, whisper.cpp, Ollama)
- Xcode project creation steps
- Package dependency addition
- Entitlements configuration
- Supabase credentials setup
- Build and run instructions
- Troubleshooting guide

## Next Steps
1. Create Xcode project in `/Users/dietmar/loopback/native/Loopback/`
2. Add Supabase Swift package dependency
3. Copy source files into Xcode project
4. Configure Info.plist and entitlements
5. Add Supabase credentials to SupabaseService.swift
5. Build and test on macOS 14+
6. Implement real-time sync with Supabase
7. Test ScreenCaptureKit audio recording
8. Verify Whisper.cpp integration