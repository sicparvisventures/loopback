"use client";

import { Meeting } from "@/types/database";
import { formatRelativeTime, formatDate, truncate, getInitials } from "@/lib/utils";
import { Bot, Calendar, Clock, CheckCircle, AlertCircle, Loader2, Search, Filter, ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import Link from "next/link";

interface MeetingsListProps {
  meetings: Meeting[];
}

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

export function MeetingsList({ meetings }: MeetingsListProps) {
  if (meetings.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <Bot className="h-16 w-16 text-muted-foreground/50 mb-4" />
        <h3 className="text-xl font-semibold mb-2">No meetings yet</h3>
        <p className="text-muted-foreground mb-6 max-w-sm">
          Connect your calendar or create a meeting manually to get started.
        </p>
        <Button asChild>
          <Link href="/dashboard/meetings/new">Create Meeting</Link>
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col sm:flex-row gap-4 justify-between items-start sm:items-center">
        <div>
          <h1 className="text-3xl font-bold">Meetings</h1>
          <p className="text-muted-foreground">{meetings.length} meeting{meetings.length !== 1 ? "s" : ""}</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" className="gap-1">
            <Filter className="h-4 w-4" />
            Filter
            <ChevronDown className="h-4 w-4" />
          </Button>
          <Button asChild>
            <Link href="/dashboard/meetings/new">New Meeting</Link>
          </Button>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {meetings.map((meeting) => {
          const config = statusConfig[meeting.status as keyof typeof statusConfig] || statusConfig.completed;
          const PlatformIcon = platformIcons[meeting.platform] || Bot;
          const StatusIcon = config.icon;

          return (
            <Card key={meeting.id} className="group hover:shadow-md transition-shadow">
              <CardHeader className="pb-2">
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <PlatformIcon className="h-4 w-4 text-muted-foreground shrink-0" />
                      <h3 className="font-semibold truncate">{meeting.title || "Untitled Meeting"}</h3>
                    </div>
                    <div className="flex items-center gap-3 text-sm text-muted-foreground">
                      <span className="flex items-center gap-1">
                        <Calendar className="h-3.5 w-3.5" />
                        {formatDate(meeting.started_at)}
                      </span>
                      {meeting.duration_seconds && (
                        <span className="flex items-center gap-1">
                          <Clock className="h-3.5 w-3.5" />
                          {Math.round(meeting.duration_seconds / 60)} min
                        </span>
                      )}
                    </div>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon" className="h-8 w-8">
                        <ChevronDown className="h-4 w-4" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem asChild>
                        <Link href={`/dashboard/meetings/${meeting.id}`}>View Details</Link>
                      </DropdownMenuItem>
                      <DropdownMenuItem asChild>
                        <Link href={`/dashboard/meetings/${meeting.id}/transcript`}>Transcript</Link>
                      </DropdownMenuItem>
                      <DropdownMenuItem asChild>
                        <Link href={`/dashboard/meetings/${meeting.id}/notes`}>Notes</Link>
                      </DropdownMenuItem>
                      <DropdownMenuItem asChild>
                        <Link href={`/dashboard/meetings/${meeting.id}/actions`}>Action Items</Link>
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </CardHeader>
              <CardContent className="pt-0">
                <div className="flex items-center justify-between">
                  <Badge variant="outline" className={cn("gap-1", config.color)}>
                    <StatusIcon className="h-3 w-3" />
                    {config.label}
                  </Badge>
                  <Link
                    href={`/dashboard/meetings/${meeting.id}`}
                    className="text-sm text-primary hover:underline font-medium"
                  >
                    View →
                  </Link>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}