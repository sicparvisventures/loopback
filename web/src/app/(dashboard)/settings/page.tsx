"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { User, Bell, Shield, Palette, Database, Key, LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Switch } from "@/components/ui/switch";
import { toast } from "sonner";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { cn } from "@/lib/utils";

const supabase = createClient();

export default function SettingsPage() {
  const [profile, setProfile] = useState({ full_name: "", timezone: "UTC" });
  const [notifications, setNotifications] = useState({ email: true, push: true, weekly: false });
  const [appearance, setAppearance] = useState({ theme: "system" });
  const [loading, setLoading] = useState(false);

  async function loadProfile() {
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      setProfile({ full_name: user.user_metadata?.full_name || "", timezone: "UTC" });
    }
  }

  async function updateProfile() {
    setLoading(true);
    const { error } = await supabase.auth.updateUser({ data: { full_name: profile.full_name } });
    if (error) toast.error(error.message);
    else toast.success("Profile updated");
    setLoading(false);
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Settings</h1>
        <p className="text-muted-foreground">Manage your account and preferences</p>
      </div>

      <Tabs defaultValue="profile" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="profile"><User className="h-4 w-4 mr-2" />Profile</TabsTrigger>
          <TabsTrigger value="notifications"><Bell className="h-4 w-4 mr-2" />Notifications</TabsTrigger>
          <TabsTrigger value="appearance"><Palette className="h-4 w-4 mr-2" />Appearance</TabsTrigger>
          <TabsTrigger value="security"><Shield className="h-4 w-4 mr-2" />Security</TabsTrigger>
        </TabsList>

        <TabsContent value="profile" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Profile</CardTitle>
              <CardDescription>Update your personal information</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center gap-6">
                <Avatar className="h-20 w-20">
                  <AvatarImage src="" alt="Avatar" />
                  <AvatarFallback className="text-2xl">
                    {profile.full_name?.charAt(0)?.toUpperCase() || "U"}
                  </AvatarFallback>
                </Avatar>
                <div className="space-y-2">
                  <Label htmlFor="fullName">Full Name</Label>
                  <Input
                    id="fullName"
                    value={profile.full_name}
                    onChange={(e) => setProfile({ ...profile, full_name: e.target.value })}
                    placeholder="Your name"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label htmlFor="timezone">Timezone</Label>
                <Input
                  id="timezone"
                  value={profile.timezone}
                  onChange={(e) => setProfile({ ...profile, timezone: e.target.value })}
                  placeholder="UTC"
                />
              </div>
              <Button onClick={updateProfile} disabled={loading}>
                {loading ? "Saving..." : "Save Changes"}
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notifications" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Notifications</CardTitle>
              <CardDescription>Configure how you want to be notified</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {[
                { key: "email", label: "Email notifications", description: "Receive meeting summaries and action items via email" },
                { key: "push", label: "Push notifications", description: "Get real-time updates in the app" },
                { key: "weekly", label: "Weekly digest", description: "Receive a weekly summary of all meetings" },
              ].map((n) => (
                <div key={n.key} className="flex items-center justify-between">
                  <div>
                    <Label className="font-medium">{n.label}</Label>
                    <p className="text-sm text-muted-foreground">{n.description}</p>
                  </div>
                  <Switch
                    checked={notifications[n.key as keyof typeof notifications]}
                    onCheckedChange={(checked) => setNotifications({ ...notifications, [n.key]: checked })}
                  />
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="appearance" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Appearance</CardTitle>
              <CardDescription>Customize how Loopback looks</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label>Theme</Label>
                <div className="grid grid-cols-3 gap-2">
                  {["light", "dark", "system"].map((t) => (
                    <Button
                      key={t}
                      variant={appearance.theme === t ? "default" : "outline"}
                      onClick={() => setAppearance({ ...appearance, theme: t })}
                      className="capitalize"
                    >
                      {t}
                    </Button>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="security" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Security</CardTitle>
              <CardDescription>Manage your account security</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div>
                  <Label className="font-medium">Two-Factor Authentication</Label>
                  <p className="text-sm text-muted-foreground">Add an extra layer of security to your account</p>
                </div>
                <Button variant="outline">Enable 2FA</Button>
              </div>
              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div>
                  <Label className="font-medium">Change Password</Label>
                  <p className="text-sm text-muted-foreground">Update your password</p>
                </div>
                <Button variant="outline">Change Password</Button>
              </div>
              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div>
                  <Label className="font-medium">Active Sessions</Label>
                  <p className="text-sm text-muted-foreground">Manage devices logged into your account</p>
                </div>
                <Button variant="outline">View Sessions</Button>
              </div>
              <Button variant="destructive" onClick={() => supabase.auth.signOut()}>
                <LogOut className="h-4 w-4 mr-2" />
                Sign Out Everywhere
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}