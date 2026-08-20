import { createClient } from "@/lib/supabase/server";
import { MeetingsList } from "@/components/dashboard/meetings-list";

export default async function MeetingsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return null;
  }

  const { data: meetings } = await supabase
    .from("meetings")
    .select("*")
    .eq("user_id", user.id)
    .order("started_at", { ascending: false })
    .limit(50);

  return <MeetingsList meetings={meetings || []} />;
}