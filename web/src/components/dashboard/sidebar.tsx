"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Bot, Search, ClipboardList, Settings, Plus, LogOut, Calendar, Users } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

const navigation = [
  { name: "Meetings", href: "/dashboard/meetings", icon: ClipboardList },
  { name: "Calendar", href: "/dashboard/calendar", icon: Calendar },
  { name: "Search", href: "/dashboard/search", icon: Search },
  { name: "Action Items", href: "/dashboard/actions", icon: ClipboardList },
];

const secondaryNavigation = [
  { name: "Team", href: "/dashboard/team", icon: Users },
  { name: "Settings", href: "/dashboard/settings", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const supabase = createClient();

  async function handleSignOut() {
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  }

  return (
    <aside className="hidden lg:flex lg:flex-col w-64 border-r bg-card h-full">
      <div className="flex h-16 items-center justify-between px-4 border-b">
        <Link href="/dashboard" className="flex items-center gap-2">
          <Bot className="h-8 w-8 text-primary" />
          <span className="text-xl font-bold">Loopback</span>
        </Link>
      </div>

      <nav className="flex-1 space-y-1 p-4" aria-label="Main navigation">
        {navigation.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                isActive
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
              )}
            >
              <item.icon className="h-5 w-5 shrink-0" aria-hidden="true" />
              {item.name}
            </Link>
          );
        })}
      </nav>

      <div className="border-t p-4">
        <Button variant="default" className="w-full gap-2 justify-start" onClick={handleSignOut}>
          <LogOut className="h-4 w-4" />
          Sign Out
        </Button>
      </div>
    </aside>
  );
}