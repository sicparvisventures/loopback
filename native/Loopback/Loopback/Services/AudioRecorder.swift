// AudioRecorder.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreGraphics
import Combine

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var error: Error?

    private var stream: SCStream?
    private var streamOutput: StreamOutput?
    private var recordingURL: URL?
    private var timer: Timer?
    private var startTime: Date?

    // Recording settings
    private let sampleRate: Double = 16000
    private let channels: AVAudioChannelCount = 1

    override init() {
        super.init()
    }

    func startRecording() async throws {
        guard !isRecording else { return }

        // Request screen recording permission
        let granted = await requestScreenCapturePermission()
        guard granted else {
            throw AudioRecorderError.permissionDenied
        }

        // Get available content
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw AudioRecorderError.noDisplayFound
        }

        // Create stream configuration
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true
        config.sampleRate = Int(sampleRate)
        config.channelCount = Int(channels)

        // Create filter for system audio
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])

        // Destination file. The audio file itself is created by StreamOutput from the
        // format of the first sample buffer, so the file always matches what the
        // stream actually delivers.
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "meeting_\(Date().timeIntervalSince1970).wav"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        recordingURL = fileURL

        // Create stream
        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        let output = StreamOutput(
            fileURL: fileURL,
            onLevel: { [weak self] level in
                Task { @MainActor [weak self] in self?.audioLevel = level }
            },
            onError: { [weak self] error in
                Task { @MainActor [weak self] in self?.error = error }
            }
        )
        // The sample handler queue must not be .main: writing to disk there would
        // stall the UI, and StreamOutput is self-contained anyway.
        try stream.addStreamOutput(output, type: .audio, sampleHandlerQueue: DispatchQueue(label: "com.loopback.audio-capture"))

        self.stream = stream
        self.streamOutput = output

        // Start stream
        try await stream.startCapture()

        isRecording = true
        startTime = Date()
        recordingDuration = 0

        // Start timer for duration updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let startTime = self.startTime else { return }
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }

    func stopRecording() async -> URL? {
        guard isRecording else { return nil }

        timer?.invalidate()
        timer = nil

        do {
            try await stream?.stopCapture()
        } catch {
            self.error = error
        }

        streamOutput?.finish()
        stream = nil
        streamOutput = nil
        isRecording = false
        audioLevel = 0

        return recordingURL
    }

    func cancelRecording() async {
        let url = await stopRecording()
        // Delete the file
        if let url {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }

    private func requestScreenCapturePermission() async -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        // Returns immediately and, on first call, shows the system prompt. The user
        // has to restart the app after granting, which macOS itself tells them.
        return CGRequestScreenCaptureAccess()
    }
}

// Stream output handler.
//
// Owns everything it touches so it can run on a background queue without
// reaching back into the main-actor-isolated recorder.
private final class StreamOutput: NSObject, SCStreamOutput {
    private let fileURL: URL
    private let onLevel: @Sendable (Float) -> Void
    private let onError: @Sendable (Error) -> Void

    private var audioFile: AVAudioFile?
    private var failed = false

    init(
        fileURL: URL,
        onLevel: @escaping @Sendable (Float) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) {
        self.fileURL = fileURL
        self.onLevel = onLevel
        self.onError = onError
    }

    /// Closes the file. `AVAudioFile` finalises the header on deallocation.
    func finish() {
        audioFile = nil
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, !failed else { return }

        guard let formatDescription = sampleBuffer.formatDescription,
              var asbd = formatDescription.audioStreamBasicDescription,
              let format = AVAudioFormat(streamDescription: &asbd) else { return }

        let frameCount = AVAudioFrameCount(sampleBuffer.numSamples)
        guard frameCount > 0 else { return }

        do {
            let file = try audioFile ?? AVAudioFile(forWriting: fileURL, settings: format.settings)
            audioFile = file

            try sampleBuffer.withAudioBufferList { bufferList, _ in
                guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, bufferListNoCopy: bufferList.unsafePointer) else { return }
                try file.write(from: pcmBuffer)
                onLevel(Self.level(of: pcmBuffer))
            }
        } catch {
            // Report once; a broken file will not fix itself mid-recording.
            failed = true
            onError(error)
        }
    }

    /// Peak-normalised RMS across the first channel, for the level meter.
    private static func level(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData, buffer.frameLength > 0 else { return 0 }
        let samples = UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength))
        let sumOfSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
        let rms = (sumOfSquares / Float(samples.count)).squareRoot()
        return min(rms * 10, 1.0)
    }
}

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case noDisplayFound
    case recordingFailed
    case fileError

    var errorDescription: String? {
        switch self {
        case .permissionDenied: return "Screen recording permission denied"
        case .noDisplayFound: return "No display found for recording"
        case .recordingFailed: return "Recording failed"
        case .fileError: return "Audio file error"
        }
    }
}
