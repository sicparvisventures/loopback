"use client";

import { useState, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Meeting } from "@/types/database";
import { formatRelativeTime, truncate } from "@/lib/utils";
import { Search, X, Filter, Loader2, MessageSquare, FileText, ClipboardList } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import Link from "next/link";
import { toast } from "sonner";

export default function SearchPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const supabase = createClient();
  const [query, setQuery] = useState(searchParams.get("q") || "");
  const [results, setResults] = useState<Meeting[]>([]);
  const [loading, setLoading] = useState(false);
  const [searchType, setSearchType] = useState<"fulltext" | "semantic">("fulltext");

  useEffect(() => {
    const trimmed = query.trim();
    // A stale in-flight request must not overwrite the results of a newer one.
    let cancelled = false;

    async function run() {
      if (!trimmed) {
        if (!cancelled) setResults([]);
        return;
      }

      setLoading(true);
      try {
        let data;
        if (searchType === "semantic") {
          // Semantic search via RPC (to be implemented)
          const { data: semanticData } = await supabase.rpc("search_meetings_semantic", {
            query_text: trimmed,
            match_count: 20,
          });
          data = semanticData;
        } else {
          // Full-text search
          const { data: fulltextData } = await supabase
            .from("meetings")
            .select("*")
            .textSearch("search_vector", trimmed, { type: "websearch" })
            .order("started_at", { ascending: false })
            .limit(20);
          data = fulltextData;
        }
        if (!cancelled) setResults(data || []);
      } catch (error) {
        console.error("Search error:", error);
        if (!cancelled) toast.error("Search failed");
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    void run();
    return () => {
      cancelled = true;
    };
  }, [query, searchType, supabase]);

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (query.trim()) {
      // The page lives at /search; the (dashboard) route group is not part of
      // the URL, so /dashboard/search would 404.
      router.push(`/search?q=${encodeURIComponent(query)}`);
    }
  }

  function clearSearch() {
    setQuery("");
    router.push("/search");
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Search Meetings</h1>
        <p className="text-muted-foreground">Find anything from your conversations</p>
      </div>

      <Card>
        <CardContent className="pt-6">
          <form onSubmit={handleSearch} className="space-y-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-muted-foreground" />
              <Input
                placeholder="Search meetings, transcripts, notes, action items..."
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                className="pl-10 h-12 text-lg"
                autoFocus
              />
              {query && (
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  className="absolute right-2 top-1/2 -translate-y-1/2"
                  onClick={clearSearch}
                >
                  <X className="h-5 w-5" />
                </Button>
              )}
            </div>

            <div className="flex items-center gap-4 text-sm text-muted-foreground">
              <div className="flex items-center gap-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="searchType"
                    value="fulltext"
                    checked={searchType === "fulltext"}
                    onChange={() => setSearchType("fulltext")}
                    className="sr-only peer"
                  />
                  <span className={cn(
                    "px-3 py-1 rounded-md text-sm font-medium transition-colors",
                    searchType === "fulltext"
                      ? "bg-primary text-primary-foreground"
                      : "bg-muted hover:bg-accent"
                  )}>
                    Full-text
                  </span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="searchType"
                    value="semantic"
                    checked={searchType === "semantic"}
                    onChange={() => setSearchType("semantic")}
                    className="sr-only peer"
                  />
                  <span className={cn(
                    "px-3 py-1 rounded-md text-sm font-medium transition-colors",
                    searchType === "semantic"
                      ? "bg-primary text-primary-foreground"
                      : "bg-muted hover:bg-accent"
                  )}>
                    Semantic
                  </span>
                </label>
              </div>
              {results.length > 0 && (
                <span>{results.length} result{results.length !== 1 ? "s" : ""}</span>
              )}
            </div>
          </form>
        </CardContent>
      </Card>

      {loading && (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      )}

      {!loading && query && results.length === 0 && (
        <div className="text-center py-12">
          <Search className="h-12 w-12 mx-auto mb-4 text-muted-foreground/50" />
          <h3 className="text-lg font-medium mb-2">No results found</h3>
          <p className="text-muted-foreground">Try different keywords or switch search mode</p>
        </div>
      )}

      {!loading && results.length > 0 && (
        <div className="space-y-4">
          {results.map((meeting) => (
            <Card key={meeting.id} className="hover:shadow-md transition-shadow">
              <CardContent className="pt-6">
                <Link href={`/dashboard/meetings/${meeting.id}`} className="block">
                  <div className="flex items-start gap-4">
                    <div className="flex-1 min-w-0">
                      <h3 className="font-semibold mb-1">{meeting.title || "Untitled Meeting"}</h3>
                      <div className="flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
                        <span>{formatRelativeTime(meeting.started_at)}</span>
                        <Badge variant="outline" className="capitalize">{meeting.platform}</Badge>
                        <Badge variant="secondary">{meeting.status}</Badge>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <Button variant="ghost" size="icon" asChild>
                        <Link href={`/dashboard/meetings/${meeting.id}/transcript`}>
                          <MessageSquare className="h-4 w-4" />
                        </Link>
                      </Button>
                      <Button variant="ghost" size="icon" asChild>
                        <Link href={`/dashboard/meetings/${meeting.id}/notes`}>
                          <FileText className="h-4 w-4" />
                        </Link>
                      </Button>
                      <Button variant="ghost" size="icon" asChild>
                        <Link href={`/dashboard/meetings/${meeting.id}/actions`}>
                          <ClipboardList className="h-4 w-4" />
                        </Link>
                      </Button>
                    </div>
                  </div>
                </Link>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}