export interface Meeting {
  id: string;
  user_id: string;
  title: string;
  platform: "zoom" | "teams" | "meet" | "local" | "manual";
  platform_meeting_id: string | null;
  started_at: string;
  ended_at: string | null;
  duration_seconds: number | null;
  status: "processing" | "completed" | "failed";
  language: string;
  audio_url: string | null;
  transcript_text: string | null;
  summary: string | null;
  notes_md: string | null;
  created_at: string;
  updated_at: string;
}

export interface TranscriptSegment {
  id: string;
  meeting_id: string;
  speaker_id: string;
  speaker_name: string | null;
  start_ms: number;
  end_ms: number;
  text: string;
  confidence: number | null;
  sequence: number;
  created_at: string;
}

export interface ActionItem {
  id: string;
  meeting_id: string;
  segment_id: string | null;
  title: string;
  description: string | null;
  assignee_name: string | null;
  assignee_email: string | null;
  due_date: string | null;
  status: "open" | "in_progress" | "done" | "cancelled";
  priority: "low" | "medium" | "high";
  created_at: string;
  updated_at: string;
}

export interface Speaker {
  id: string;
  user_id: string;
  name: string;
  email: string | null;
  avatar_url: string | null;
  created_at: string;
}

export interface MeetingSpeaker {
  id: string;
  meeting_id: string;
  speaker_id: string;
  platform_speaker_id: string | null;
  display_name: string | null;
  created_at: string;
}

export interface Profile {
  id: string;
  display_name: string | null;
  avatar_url: string | null;
  timezone: string;
  created_at: string;
  updated_at: string;
}

export type MeetingWithRelations = Meeting & {
  transcript_segments?: TranscriptSegment[];
  action_items?: ActionItem[];
  meeting_speakers?: (MeetingSpeaker & { speaker: Speaker })[];
};