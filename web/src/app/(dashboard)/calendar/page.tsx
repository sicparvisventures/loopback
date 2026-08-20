"use client";

import { useState } from "react";
import { Calendar, Plus, ChevronLeft, ChevronRight, Sun } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import Link from "next/link";
import { format } from "date-fns";

export default function CalendarPage() {
  const [currentDate, setCurrentDate] = useState(new Date());

  const daysInMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getDate();
  const firstDayOfMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1).getDay();
  const today = new Date();

  const mockMeetings = {
    "2025-08-20": [{ title: "Team Standup", time: "09:00" }, { title: "Client Call", time: "14:00" }],
    "2025-08-21": [{ title: "Sprint Planning", time: "10:00" }],
    "2025-08-25": [{ title: "Budget Review", time: "11:00" }],
  };

  function getMeetingsForDay(day: number) {
    const dateStr = format(new Date(currentDate.getFullYear(), currentDate.getMonth(), day), "yyyy-MM-dd");
    return mockMeetings[dateStr as keyof typeof mockMeetings] || [];
  }

  function isToday(day: number) {
    const date = new Date(currentDate.getFullYear(), currentDate.getMonth(), day);
    return format(date, "yyyy-MM-dd") === format(today, "yyyy-MM-dd");
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold">Calendar</h1>
          <p className="text-muted-foreground">View and manage your meeting schedule</p>
        </div>
        <div className="flex items-center gap-2">
<Button variant="outline" size="sm" onClick={() => setCurrentDate(new Date())}>
  <Sun className="h-4 w-4 mr-2" />
  Today
</Button>
          <Button asChild>
            <Link href="/dashboard/meetings/new">New Meeting</Link>
          </Button>
        </div>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-2xl">{format(currentDate, "MMMM yyyy")}</CardTitle>
            <div className="flex items-center gap-2">
              <Button variant="outline" size="icon" onClick={() => setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1))}>
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <Button variant="outline" size="icon" onClick={() => setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1))}>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-7 gap-1 mb-2">
            {["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].map((day) => (
              <div key={day} className="text-center text-sm font-medium text-muted-foreground py-2">
                {day}
              </div>
            ))}
          </div>
          <div className="grid grid-cols-7 gap-1">
            {/* Empty cells before first day */}
            {Array.from({ length: firstDayOfMonth }).map((_, i) => (
              <div key={i} className="aspect-square" />
            ))}
            {/* Days of month */}
            {Array.from({ length: daysInMonth }).map((_, i) => {
              const day = i + 1;
              const meetings = getMeetingsForDay(day);
              return (
                <div
                  key={day}
                  className={cn(
                    "aspect-square relative p-1 rounded-lg hover:bg-accent transition-colors",
                    isToday(day) && "bg-primary/10 ring-2 ring-primary"
                  )}
                >
                  <span className={cn("text-sm font-medium", isToday(day) && "text-primary")}>{day}</span>
                  {meetings.length > 0 && (
                    <div className="mt-1 space-y-1">
                      {meetings.slice(0, 3).map((m, idx) => (
                        <div
                          key={idx}
                          className="text-xs bg-primary/20 text-primary px-1.5 py-0.5 rounded truncate"
                        >
                          {m.time} {m.title}
                        </div>
                      ))}
                      {meetings.length > 3 && (
                        <div className="text-xs text-muted-foreground">+{meetings.length - 3} more</div>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}