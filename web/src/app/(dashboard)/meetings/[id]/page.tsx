import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { MeetingDetailClient } from "@/components/dashboard/meeting-detail-client";

interface MeetingDetailPageProps {
  params: Promise<{ id: string }>;
}

export default async function MeetingDetailPage({ params }: MeetingDetailPageProps) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return notFound();
  }

  const { data: meeting } = await supabase
    .from("meetings")
    .select("*")
    .eq("id", id)
    .eq("user_id", user.id)
    .single();

  if (!meeting) {
    return notFound();
  }

  return <MeetingDetailClient meeting={meeting} />;
}