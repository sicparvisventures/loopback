// Meeting.swift
// Loopback
//
// Created by Dietmar on 2025-08-20.
//

import Foundation
import SwiftData

@Model
final class Meeting {
    var id: UUID
    var userId: UUID
    var title: String
    var platform: String
    var platformMeetingId: String?
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int?
    var status: String
    var language: String
    var audioUrl: String?
    var transcriptText: String?
    var summary: String?
    var notesMd: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TranscriptSegment.meeting)
    var transcriptSegments: [TranscriptSegment] = []

    @Relationship(deleteRule: .cascade, inverse: \ActionItem.meeting)
    var actionItems: [ActionItem] = []

    @Relationship(deleteRule: .cascade, inverse: \MeetingSpeaker.meeting)
    var meetingSpeakers: [MeetingSpeaker] = []

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        platform: String,
        platformMeetingId: String? = nil,
        startedAt: Date,
        endedAt: Date? = nil,
        durationSeconds: Int? = nil,
        status: String = "processing",
        language: String = "en",
        audioUrl: String? = nil,
        transcriptText: String? = nil,
        summary: String? = nil,
        notesMd: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.platform = platform
        self.platformMeetingId = platformMeetingId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.status = status
        self.language = language
        self.audioUrl = audioUrl
        self.transcriptText = transcriptText
        self.summary = summary
        self.notesMd = notesMd
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class TranscriptSegment {
    var id: UUID
    var meetingId: UUID
    var speakerId: String
    var speakerName: String?
    var startMs: Int
    var endMs: Int
    var text: String
    var confidence: Double?
    var sequence: Int
    var createdAt: Date

    var meeting: Meeting?

    init(
        id: UUID = UUID(),
        meetingId: UUID,
        speakerId: String,
        speakerName: String? = nil,
        startMs: Int,
        endMs: Int,
        text: String,
        confidence: Double? = nil,
        sequence: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.meetingId = meetingId
        self.speakerId = speakerId
        self.speakerName = speakerName
        self.startMs = startMs
        self.endMs = endMs
        self.text = text
        self.confidence = confidence
        self.sequence = sequence
        self.createdAt = createdAt
    }
}

@Model
final class ActionItem {
    var id: UUID
    var meetingId: UUID
    var segmentId: UUID?
    var title: String
    var descriptionText: String?
    var assigneeName: String?
    var assigneeEmail: String?
    var dueDate: Date?
    var status: String
    var priority: String
    var createdAt: Date
    var updatedAt: Date

    var meeting: Meeting?

    init(
        id: UUID = UUID(),
        meetingId: UUID,
        segmentId: UUID? = nil,
        title: String,
        descriptionText: String? = nil,
        assigneeName: String? = nil,
        assigneeEmail: String? = nil,
        dueDate: Date? = nil,
        status: String = "open",
        priority: String = "medium",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.meetingId = meetingId
        self.segmentId = segmentId
        self.title = title
        self.descriptionText = descriptionText
        self.assigneeName = assigneeName
        self.assigneeEmail = assigneeEmail
        self.dueDate = dueDate
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class Speaker {
    var id: UUID
    var userId: UUID
    var name: String
    var email: String?
    var avatarUrl: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        email: String? = nil,
        avatarUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.email = email
        self.avatarUrl = avatarUrl
        self.createdAt = createdAt
    }
}

@Model
final class MeetingSpeaker {
    var id: UUID
    var meetingId: UUID
    var speakerId: UUID
    var platformSpeakerId: String?
    var displayName: String?
    var createdAt: Date

    var meeting: Meeting?
    var speaker: Speaker?

    init(
        id: UUID = UUID(),
        meetingId: UUID,
        speakerId: UUID,
        platformSpeakerId: String? = nil,
        displayName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.meetingId = meetingId
        self.speakerId = speakerId
        self.platformSpeakerId = platformSpeakerId
        self.displayName = displayName
        self.createdAt = createdAt
    }
}