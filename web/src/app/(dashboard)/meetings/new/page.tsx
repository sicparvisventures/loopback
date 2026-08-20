"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Calendar, Clock, Plus, ArrowLeft } from "lucide-react";
import Link from "next/link";
import { toast } from "sonner";
import { cn } from "@/lib/utils";

export default function NewMeetingPage() {
  const router = useRouter();
  const supabase = createClient();
  const [title, setTitle] = useState("");
  const [platform, setPlatform] = useState<"zoom" | "teams" | "meet" | "local" | "manual">("manual");
  const [startedAt, setStartedAt] = useState(new Date().toISOString().slice(0, 16));
  const [duration, setDuration] = useState(30);
  const [loading, setLoading] = useState(false);

  const platforms = [
    { value: "manual", label: "Manual Entry", icon: "📝" },
    { value: "zoom", label: "Zoom", icon: "🔵" },
    { value: "teams", label: "Microsoft Teams", icon: "🟣" },
    { value: "meet", label: "Google Meet", icon: "🟢" },
    { value: "local", label: "Local Recording", icon: "🎙️" },
  ];

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      toast.error("Please sign in first");
      setLoading(false);
      return;
    }

    const startedAtDate = new Date(startedAt);
    const endedAtDate = new Date(startedAtDate.getTime() + duration * 60000);

    const { data, error } = await supabase
      .from("meetings")
      .insert({
        user_id: user.id,
        title: title || "Untitled Meeting",
        platform,
        started_at: startedAtDate.toISOString(),
        ended_at: endedAtDate.toISOString(),
        duration_seconds: duration * 60,
        status: "completed",
        language: "en",
      })
      .select()
      .single();

    if (error) {
      toast.error(error.message);
      setLoading(false);
      return;
    }

    toast.success("Meeting created!");
    router.push(`/dashboard/meetings/${data.id}`);
    router.refresh();
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/dashboard/meetings" className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="h-5 w-5" />
        </Link>
        <div>
          <h1 className="text-3xl font-bold">New Meeting</h1>
          <p className="text-muted-foreground">Create a meeting entry manually</p>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Meeting Details</CardTitle>
          <CardDescription>Fill in the details for your meeting</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="title">Title</Label>
              <Input
                id="title"
                placeholder="e.g., Weekly Team Sync"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
              />
            </div>

            <div className="space-y-2">
              <Label>Platform</Label>
              <Select value={platform} onValueChange={(v) => setPlatform(v as "zoom" | "teams" | "meet" | "local" | "manual")}>
                <SelectTrigger>
                  <SelectValue placeholder="Select platform" />
                </SelectTrigger>
                <SelectContent>
                  {platforms.map((p) => (
                    <SelectItem key={p.value} value={p.value}>
                      <span className="flex items-center gap-2">
                        <span>{p.icon}</span>
                        {p.label}
                      </span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="startedAt">Date & Time</Label>
                <Input
                  id="startedAt"
                  type="datetime-local"
                  value={startedAt}
                  onChange={(e) => setStartedAt(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="duration">Duration (minutes)</Label>
                <Input
                  id="duration"
                  type="number"
                  min="1"
                  max="480"
                  value={duration}
                  onChange={(e) => setDuration(parseInt(e.target.value) || 0)}
                />
              </div>
            </div>

            <div className="flex justify-end gap-3 pt-4 border-t">
              <Button type="button" variant="outline" asChild>
                <Link href="/dashboard/meetings">Cancel</Link>
              </Button>
              <Button type="submit" disabled={loading} className="gap-2">
                <Plus className="h-4 w-4" />
                {loading ? "Creating..." : "Create Meeting"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}