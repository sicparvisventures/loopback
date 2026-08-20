// AudioRecorder.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import Foundation
import ScreenCaptureKit
import AVFoundation
import Combine

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var error: Error?
    
    private var stream: SCStream?
    private var streamOutput: StreamOutput?
    private var audioFile: AVAudioFile?
    private var audioEngine: AVAudioEngine?
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
        
        // Create stream
        stream = SCStream(filter: filter, configuration: config, delegate: nil)
        streamOutput = StreamOutput(recorder: self)
        
        try stream?.addStreamOutput(streamOutput!, type: .audio, sampleHandlerQueue: .main)
        
        // Setup audio file for writing
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "meeting_\(Date().timeIntervalSince1970).wav"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channels)!
        audioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
        
        // Start stream
        try await stream?.startCapture()
        
        isRecording = true
        startTime = Date()
        recordingDuration = 0
        
        // Start timer for duration updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
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
        
        stream = nil
        streamOutput = nil
        isRecording = false
        
        return audioFile?.url
    }
    
    func cancelRecording() async {
        _ = await stopRecording()
        // Delete the file
        if let url = audioFile?.url {
            try? FileManager.default.removeItem(at: url)
        }
        audioFile = nil
    }
    
    private func requestScreenCapturePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SCRequestScreenCaptureAccess { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

// Stream output handler
private class StreamOutput: NSObject, SCStreamOutput {
    weak var recorder: AudioRecorder?
    
    init(recorder: AudioRecorder) {
        self.recorder = recorder
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio,
              let recorder = recorder,
              let audioFile = recorder.audioFile else { return }
        
        // Convert CMSampleBuffer to AVAudioPCMBuffer and write to file
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        
        let length = CMBlockBufferGetDataLength(blockBuffer)
        var data = Data(count: length)
        data.withUnsafeMutableBytes { ptr in
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: ptr.baseAddress!)
        }
        
        // Write to audio file
        do {
            let format = AVAudioFormat(standardFormatWithSampleRate: recorder.sampleRate, channels: recorder.channels)!
            let frameCount = AVAudioFrameCount(length) / AVAudioFrameCount(format.streamDescription.pointee.mBytesPerFrame)
            if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
                buffer.frameLength = frameCount
                data.withUnsafeBytes { ptr in
                    memcpy(buffer.floatChannelData?[0], ptr.baseAddress, length)
                }
                try audioFile.write(from: buffer)
            }
        } catch {
            recorder.error = error
        }
        
        // Calculate audio level for visualization
        if let channelData = data.withUnsafeBytes({ $0.bindMemory(to: Float.self) }) {
            let rms = sqrt(channelData.map { $0 * $0 }.reduce(0, +) / Float(channelData.count))
            DispatchQueue.main.async {
                self.recorder?.audioLevel = min(rms * 10, 1.0)
            }
        }
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