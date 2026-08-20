"use client";

import { useState } from "react";
import Link from "next/link";
import { Meeting } from "@/types/database";
import { formatDate, formatRelativeTime, getInitials } from "@/lib/utils";
import { Bot, Calendar, Clock, Download, Share2, Edit, Trash2, Loader2, CheckCircle, AlertCircle, FileText, Mic, MessageSquare, ClipboardList } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { cn } from "@/lib/utils";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

const statusConfig = {
  completed: { label: "Completed", icon: CheckCircle, color: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400" },
  processing: { label: "Processing", icon: Loader2, color: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400" },
  failed: { label: "Failed", icon: AlertCircle, color: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400" },
} as const;

const platformIcons = {
  zoom: Bot,
  teams: Calendar,
  meet: Bot,
  local: Bot,
  manual: Calendar,
};

interface MeetingDetailClientProps {
  meeting: Meeting;
}

export function MeetingDetailClient({ meeting }: MeetingDetailClientProps) {
  const [activeTab, setActiveTab] = useState("overview");
  const config = statusConfig[meeting.status as keyof typeof statusConfig] || statusConfig.completed;
  const PlatformIcon = platformIcons[meeting.platform] || Bot;
  const StatusIcon = config.icon;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
        <div className="flex-1">
          <div className="flex items-center gap-3 mb-2">
            <PlatformIcon className="h-6 w-6 text-muted-foreground" />
            <h1 className="text-2xl font-bold">{meeting.title || "Untitled Meeting"}</h1>
            <Badge variant="outline" className={cn(config.color)}>
              <StatusIcon className="h-3 w-3" />
              {config.label}
            </Badge>
          </div>
          <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
            <span className="flex items-center gap-1">
              <Calendar className="h-4 w-4" />
              {formatDate(meeting.started_at)}
            </span>
            {meeting.ended_at && (
              <span className="flex items-center gap-1">
                <Clock className="h-4 w-4" />
                {formatRelativeTime(meeting.ended_at)}
              </span>
            )}
            {meeting.duration_seconds && (
              <span className="flex items-center gap-1">
                <Clock className="h-4 w-4" />
                {Math.round(meeting.duration_seconds / 60)} min
              </span>
            )}
            {meeting.language && (
              <span className="flex items-center gap-1">
                <span className="text-xs uppercase">{meeting.language}</span>
              </span>
            )}
          </div>
        </div>

        <div className="flex items-center gap-2">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" className="gap-2">
                <Download className="h-4 w-4" />
                Export
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem>Export as PDF</DropdownMenuItem>
              <DropdownMenuItem>Export as Markdown</DropdownMenuItem>
              <DropdownMenuItem>Export as JSON</DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <Button variant="outline" className="gap-2">
            <Share2 className="h-4 w-4" />
            Share
          </Button>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="transcript">
            <Mic className="h-4 w-4 mr-2" />
            Transcript
          </TabsTrigger>
          <TabsTrigger value="notes">
            <FileText className="h-4 w-4 mr-2" />
            Notes
          </TabsTrigger>
          <TabsTrigger value="actions">
            <ClipboardList className="h-4 w-4 mr-2" />
            Actions
          </TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="space-y-6">
          {/* Summary */}
          {meeting.summary && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <FileText className="h-5 w-5" />
                  Summary
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="prose prose-sm max-w-none">{meeting.summary}</div>
              </CardContent>
            </Card>
          )}

          {/* Metadata */}
          <div className="grid gap-4 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Bot className="h-5 w-5" />
                  Meeting Info
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Platform</span>
                  <span className="font-medium capitalize">{meeting.platform}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Started</span>
                  <span className="font-medium">{formatDate(meeting.started_at)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Ended</span>
                  <span className="font-medium">{meeting.ended_at ? formatDate(meeting.ended_at) : "—"}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Duration</span>
                  <span className="font-medium">{meeting.duration_seconds ? `${Math.round(meeting.duration_seconds / 60)} min` : "—"}</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <ClipboardList className="h-5 w-5" />
                  Quick Actions
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <Button variant="outline" className="w-full justify-start gap-2" asChild>
                  <Link href={`/dashboard/meetings/${meeting.id}/transcript`}>
                    <Mic className="h-4 w-4" />
                    View Transcript
                  </Link>
                </Button>
                <Button variant="outline" className="w-full justify-start gap-2" asChild>
                  <Link href={`/dashboard/meetings/${meeting.id}/notes`}>
                    <FileText className="h-4 w-4" />
                    View Notes
                  </Link>
                </Button>
                <Button variant="outline" className="w-full justify-start gap-2" asChild>
                  <Link href={`/dashboard/meetings/${meeting.id}/actions`}>
                    <ClipboardList className="h-4 w-4" />
                    View Action Items
                  </Link>
                </Button>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="transcript">
          <Card>
            <CardHeader>
              <CardTitle>Transcript</CardTitle>
            </CardHeader>
            <CardContent>
              {meeting.transcript_text ? (
                <div className="prose prose-sm max-w-none whitespace-pre-wrap">{meeting.transcript_text}</div>
              ) : (
                <div className="text-center py-12 text-muted-foreground">
                  <Mic className="h-12 w-12 mx-auto mb-4 text-muted-foreground/50" />
                  <p>No transcript available yet.</p>
                  {meeting.status === "processing" && <p className="mt-2">Processing...</p>}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notes">
          <Card>
            <CardHeader>
              <CardTitle>Notes</CardTitle>
            </CardHeader>
            <CardContent>
              {meeting.notes_md ? (
                <div className="prose prose-sm max-w-none">{meeting.notes_md}</div>
              ) : (
                <div className="text-center py-12 text-muted-foreground">
                  <FileText className="h-12 w-12 mx-auto mb-4 text-muted-foreground/50" />
                  <p>No notes generated yet.</p>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="actions">
          <Card>
            <CardHeader>
              <CardTitle>Action Items</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-center py-12 text-muted-foreground">
                <ClipboardList className="h-12 w-12 mx-auto mb-4 text-muted-foreground/50" />
                <p>Action items will appear here after processing.</p>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}