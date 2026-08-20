"use client";

import { useState } from "react";
import { Users, Plus, Mail, Shield, MoreHorizontal, UserCheck, UserX } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { cn } from "@/lib/utils";
import { toast } from "sonner";

const mockMembers = [
  { id: "1", name: "You", email: "you@example.com", role: "owner", avatar: null, status: "active" },
  { id: "2", name: "Sarah Chen", email: "sarah@example.com", role: "admin", avatar: null, status: "active" },
  { id: "3", name: "Mike Johnson", email: "mike@example.com", role: "member", avatar: null, status: "active" },
  { id: "4", name: "Emily Davis", email: "emily@example.com", role: "member", avatar: null, status: "pending" },
];

const roleConfig = {
  owner: { label: "Owner", color: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-400" },
  admin: { label: "Admin", color: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400" },
  member: { label: "Member", color: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400" },
};

export default function TeamPage() {
  const [showInvite, setShowInvite] = useState(false);
  const [email, setEmail] = useState("");
  const [role, setRole] = useState<"admin" | "member">("member");

  function getInitials(name: string) {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold">Team</h1>
          <p className="text-muted-foreground">Manage team members and permissions</p>
        </div>
        <Button onClick={() => setShowInvite(true)} className="gap-2">
          <Plus className="h-4 w-4" />
          Invite Member
        </Button>
      </div>

      {/* Invite Modal */}
      {showInvite && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <Card className="w-full max-w-md mx-4">
            <CardHeader>
              <CardTitle>Invite Team Member</CardTitle>
              <CardDescription>Enter their email address to send an invitation</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="inviteEmail">Email</Label>
                <Input
                  id="inviteEmail"
                  type="email"
                  placeholder="colleague@company.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoFocus
                />
              </div>
              <div className="space-y-2">
                <Label>Role</Label>
                <div className="grid grid-cols-2 gap-2">
                  {["admin", "member"].map((r) => (
                    <Button
                      key={r}
                      variant={role === r ? "default" : "outline"}
                      onClick={() => setRole(r as "admin" | "member")}
                      className="capitalize"
                    >
                      {r}
                    </Button>
                  ))}
                </div>
              </div>
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => { setShowInvite(false); setEmail(""); }}>Cancel</Button>
                <Button onClick={() => { toast.success(`Invitation sent to ${email}`); setShowInvite(false); setEmail(""); }}>
                  Send Invitation
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Team Members</CardTitle>
          <CardDescription>{mockMembers.length} member{mockMembers.length !== 1 ? "s" : ""}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {mockMembers.map((member) => (
              <div
                key={member.id}
                className="flex items-center justify-between p-4 border rounded-lg hover:bg-accent/50 transition-colors"
              >
                <div className="flex items-center gap-4">
                  <Avatar className="h-10 w-10">
                    <AvatarImage src={member.avatar || ""} alt={member.name} />
                    <AvatarFallback>{getInitials(member.name)}</AvatarFallback>
                  </Avatar>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-medium">{member.name}</span>
                      {member.id === "1" && <Badge variant="secondary" className="text-xs">You</Badge>}
                    </div>
                    <p className="text-sm text-muted-foreground">{member.email}</p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <Badge variant="outline" className={cn(roleConfig[member.role as keyof typeof roleConfig]?.color)}>
                    {roleConfig[member.role as keyof typeof roleConfig]?.label}
                  </Badge>
                  <Badge variant={member.status === "active" ? "default" : "outline"}>
                    {member.status}
                  </Badge>
                  {member.id !== "1" && (
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuLabel>Member Actions</DropdownMenuLabel>
                        {member.role !== "owner" && (
                          <>
                            <DropdownMenuItem onClick={() => toast.success("Role updated")}>
                              <Shield className="h-4 w-4 mr-2" />
                              Make Admin
                            </DropdownMenuItem>
                            <DropdownMenuItem className="text-destructive" onClick={() => toast.success("Member removed")}>
                              <UserX className="h-4 w-4 mr-2" />
                              Remove from Team
                            </DropdownMenuItem>
                          </>
                        )}
                      </DropdownMenuContent>
                    </DropdownMenu>
                  )}
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}