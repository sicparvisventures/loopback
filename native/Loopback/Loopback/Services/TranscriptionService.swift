// TranscriptionService.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import Foundation

@MainActor
class TranscriptionService: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var error: Error?
    
    private let whisperPath: String
    private let modelPath: String
    
    override init() {
        // Default paths - user can configure
        self.whisperPath = "/opt/homebrew/bin/whisper-cli" // or wherever whisper.cpp is installed
        self.modelPath = "/opt/homebrew/share/whisper.cpp/models/ggml-large-v3.bin"
        super.init()
    }
    
    func transcribe(audioURL: URL, language: String = "en") async throws -> TranscriptionResult {
        isProcessing = true
        progress = 0
        defer { isProcessing = false }
        
        // Check if whisper.cpp is available
        guard FileManager.default.fileExists(atPath: whisperPath) else {
            throw TranscriptionError.whisperNotFound
        }
        
        // Build command
        let arguments = [
            "-m", modelPath,
            "-f", audioURL.path,
            "-l", language,
            "-oj", // JSON output
            "-otxt", // Text output
            "-osrt", // SRT output
            "-owts" // Word timestamps
        ]
        
        // Run whisper.cpp
        let process = Process()
        process.executableURL = URL(fileURLWithPath: whisperPath)
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Monitor progress via stderr
        errorPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8) {
                self?.parseProgress(output)
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            // Parse output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            
            if process.terminationStatus != 0 {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
                throw TranscriptionError.processFailed(errorOutput)
            }
            
            // Parse JSON output
            let jsonURL = audioURL.deletingPathExtension().appendingPathExtension("json")
            if FileManager.default.fileExists(atPath: jsonURL.path) {
                let jsonData = try Data(contentsOf: jsonURL)
                let result = try JSONDecoder().decode(WhisperJSONResult.self, from: jsonData)
                return TranscriptionResult(from: result)
            }
            
            // Fallback to text output
            let textURL = audioURL.deletingPathExtension().appendingPathExtension("txt")
            if FileManager.default.fileExists(atPath: textURL.path) {
                let text = try String(contentsOf: textURL, encoding: .utf8)
                return TranscriptionResult(text: text, segments: [], language: language)
            }
            
            throw TranscriptionError.noOutput
        } catch {
            self.error = error
            throw error
        }
    }
    
    private func parseProgress(_ output: String) {
        // Parse whisper.cpp progress output
        // Example: "[PROGRESS] 45.2%"
        let pattern = "\\[PROGRESS\\]\\s*(\\d+(?:\\.\\d+)?)%"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: output.utf16.count)
        
        if let match = regex?.firstMatch(in: output, range: range),
           let range = Range(match.range(at: 1), in: output),
           let value = Double(output[range]) {
            progress = value / 100.0
        }
    }
}

struct TranscriptionResult {
    let text: String
    let segments: [TranscriptSegmentData]
    let language: String
    let duration: TimeInterval
    
    init(from whisperResult: WhisperJSONResult) {
        self.text = whisperResult.text
        self.segments = whisperResult.segments.map { TranscriptSegmentData(from: $0) }
        self.language = whisperResult.language
        self.duration = whisperResult.segments.last?.end ?? 0
    }
    
    init(text: String, segments: [TranscriptSegmentData], language: String) {
        self.text = text
        self.segments = segments
        self.language = language
        self.duration = segments.last?.end ?? 0
    }
}

struct TranscriptSegmentData {
    let id: Int
    let start: TimeInterval
    let end: TimeInterval
    let text: String
    let speaker: String?
    
    init(from whisperSegment: WhisperJSONSegment) {
        self.id = whisperSegment.id
        self.start = whisperSegment.start
        self.end = whisperSegment.end
        self.text = whisperSegment.text
        self.speaker = nil // Will be filled by diarization
    }
}

// Whisper.cpp JSON output structures
struct WhisperJSONResult: Codable {
    let text: String
    let segments: [WhisperJSONSegment]
    let language: String
}

struct WhisperJSONSegment: Codable {
    let id: Int
    let start: TimeInterval
    let end: TimeInterval
    let text: String
}

enum TranscriptionError: LocalizedError {
    case whisperNotFound
    case processFailed(String)
    case noOutput
    case invalidAudioFile
    
    var errorDescription: String? {
        switch self {
        case .whisperNotFound: return "whisper.cpp not found. Install with: brew install whisper.cpp"
        case .processFailed(let output): return "Transcription failed: \(output)"
        case .noOutput: return "No transcription output generated"
        case .invalidAudioFile: return "Invalid audio file format"
        }
    }
}