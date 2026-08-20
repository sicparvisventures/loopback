"use client";

import { ClipboardList, Plus, CheckCircle, AlertCircle, Clock, Filter, ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { cn } from "@/lib/utils";
import Link from "next/link";

const mockActions = [
  { id: "1", title: "Send follow-up email to client", meeting: "Client Call - Q3 Review", assignee: "You", dueDate: "2025-08-22", status: "open", priority: "high" },
  { id: "2", title: "Update project timeline in Linear", meeting: "Sprint Planning", assignee: "Sarah", dueDate: "2025-08-25", status: "in_progress", priority: "medium" },
  { id: "3", title: "Review and approve budget", meeting: "Budget Meeting", assignee: "Mike", dueDate: "2025-08-20", status: "done", priority: "high" },
  { id: "4", title: "Prepare demo for stakeholders", meeting: "Product Review", assignee: "You", dueDate: "2025-08-28", status: "open", priority: "medium" },
];

const statusConfig = {
  open: { label: "Open", color: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400" },
  in_progress: { label: "In Progress", color: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400" },
  done: { label: "Done", color: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400" },
  cancelled: { label: "Cancelled", color: "bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400" },
};

const priorityConfig = {
  high: { label: "High", color: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400" },
  medium: { label: "Medium", color: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400" },
  low: { label: "Low", color: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400" },
};

export default function ActionsPage() {
  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold">Action Items</h1>
          <p className="text-muted-foreground">Track and manage tasks from your meetings</p>
        </div>
        <Button asChild>
          <Link href="/dashboard/actions/new">New Action Item</Link>
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Action Items</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {mockActions.map((action) => (
              <div
                key={action.id}
                className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 p-4 border rounded-lg hover:bg-accent/50 transition-colors"
              >
                <div className="flex-1 min-w-0">
                  <h3 className="font-medium mb-1">{action.title}</h3>
                  <div className="flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <ClipboardList className="h-3.5 w-3.5" />
                      {action.meeting}
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock className="h-3.5 w-3.5" />
                      Due: {action.dueDate}
                    </span>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <Badge variant="outline" className={cn(statusConfig[action.status as keyof typeof statusConfig]?.color)}>
                    {statusConfig[action.status as keyof typeof statusConfig]?.label}
                  </Badge>
                  <Badge variant="outline" className={cn(priorityConfig[action.priority as keyof typeof priorityConfig]?.color)}>
                    {priorityConfig[action.priority as keyof typeof priorityConfig]?.label}
                  </Badge>
                  <Button variant="ghost" size="icon" asChild>
                    <Link href={`/dashboard/actions/${action.id}`}>Edit</Link>
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}