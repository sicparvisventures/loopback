import Link from "next/link";
import { Bot, Search, ClipboardList, Mic, ArrowRight, CheckCircle, Shield, Zap } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

const features = [
  {
    icon: Mic,
    title: "Automatic Transcription",
    description: "Real-time transcription with 95%+ accuracy across 100+ languages. Speaker diarization identifies who said what.",
  },
  {
    icon: ClipboardList,
    title: "Structured Notes & Actions",
    description: "AI generates organized notes with summaries, key decisions, and action items with assignees and due dates.",
  },
  {
    icon: Search,
    title: "Search Every Conversation",
    description: "Full-text and semantic search across all your meetings. Find decisions, discussions, and action items instantly.",
  },
  {
    icon: Bot,
    title: "Meeting Bot",
    description: "Joins Zoom, Teams, and Google Meet as a participant. Records automatically from your calendar.",
  },
  {
    icon: Shield,
    title: "Privacy-First",
    description: "Local AI processing with Whisper.cpp and Ollama. Your audio and transcripts never leave your infrastructure.",
  },
  {
    icon: Zap,
    title: "Integrations",
    description: "Export to Notion, Linear, Slack, and more. API and webhooks for custom workflows.",
  },
];

const stats = [
  { value: "95%+", label: "Transcription Accuracy" },
  { value: "100+", label: "Languages Supported" },
  { value: "< 60s", label: "Processing Time" },
  { value: "100%", label: "Private & Local" },
];

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen bg-background">
      {/* Header */}
      <header className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-50">
        <div className="container mx-auto flex h-16 items-center justify-between px-4">
          <div className="flex items-center gap-2">
            <Bot className="h-8 w-8 text-primary" />
            <span className="text-xl font-bold">Loopback</span>
          </div>
          <nav className="hidden md:flex items-center gap-6">
            <Link href="#features" className="text-sm font-medium text-muted-foreground hover:text-foreground">
              Features
            </Link>
            <Link href="#how-it-works" className="text-sm font-medium text-muted-foreground hover:text-foreground">
              How It Works
            </Link>
            <Link href="/login" className="text-sm font-medium text-muted-foreground hover:text-foreground">
              Sign In
            </Link>
            <Link href="/signup">
              <Button size="sm">Get Started Free</Button>
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero */}
      <main className="flex-1">
        <section className="container mx-auto py-24 px-4 text-center">
          <div className="max-w-3xl mx-auto">
            <div className="inline-flex items-center gap-2 rounded-full bg-primary/10 px-3 py-1 text-sm font-medium text-primary mb-6">
              <Zap className="h-4 w-4" />
              <span>Now with local AI - Whisper.cpp + Ollama</span>
            </div>
            <h1 className="text-5xl md:text-7xl font-bold tracking-tight mb-6">
              Unbelievably good{" "}
              <span className="text-primary">meeting notes</span>
              , automatically.
            </h1>
            <p className="text-xl text-muted-foreground mb-10 max-w-2xl mx-auto">
              Loopback captures, transcribes, and organizes your meetings so you can focus on what matters.
              Built with local AI for complete privacy.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16">
              <Link href="/signup">
                <Button size="lg" className="gap-2 w-full sm:w-auto">
                  Start Free
                  <ArrowRight className="h-4 w-4" />
                </Button>
              </Link>
              <Link href="#features">
                <Button size="lg" variant="outline" className="w-full sm:w-auto">
                  See How It Works
                </Button>
              </Link>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-16">
              {stats.map((stat) => (
                <div key={stat.label} className="text-center">
                  <div className="text-4xl md:text-5xl font-bold text-primary">{stat.value}</div>
                  <div className="text-sm text-muted-foreground mt-1">{stat.label}</div>
                </div>
              ))}
            </div>

            {/* Trust badges */}
            <div className="flex flex-wrap items-center justify-center gap-8 text-muted-foreground/50 text-sm">
              <span>Loved by teams at</span>
              <span>Y Combinator</span>
              <span>Vercel</span>
              <span>Runway</span>
              <span>Harvard</span>
              <span>Stanford</span>
            </div>
          </div>
        </section>

        {/* Features */}
        <section id="features" className="bg-muted/30 py-24 px-4">
          <div className="container mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl font-bold mb-4">Everything you need to never miss a detail</h2>
              <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
                From automatic transcription to actionable insights, Loopback handles the busywork so you don't have to.
              </p>
            </div>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
              {features.map((feature) => (
                <Card key={feature.title} className="h-full border-border/50 hover:border-primary/50 transition-colors">
                  <CardHeader>
                    <feature.icon className="h-10 w-10 text-primary mb-2" />
                    <CardTitle>{feature.title}</CardTitle>
                    <CardDescription>{feature.description}</CardDescription>
                  </CardHeader>
                </Card>
              ))}
            </div>
          </div>
        </section>

        {/* How It Works */}
        <section id="how-it-works" className="py-24 px-4">
          <div className="container mx-auto">
            <div className="text-center mb-16">
              <h2 className="text-4xl font-bold mb-4">How it works</h2>
              <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
                Set up once, then Loopback works automatically in the background.
              </p>
            </div>
            <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
              <div className="text-center relative">
                <div className="absolute left-1/2 top-10 -translate-x-1/2 w-1 h-20 bg-border hidden md:block" />
                <div className="relative z-10 w-20 h-20 rounded-full bg-primary flex items-center justify-center mx-auto mb-4">
                  <span className="text-2xl font-bold text-primary-foreground">1</span>
                </div>
                <h3 className="text-xl font-bold mb-2">Connect Calendar</h3>
                <p className="text-muted-foreground">Link Google Calendar or Outlook. Loopback detects upcoming meetings automatically.</p>
              </div>
              <div className="text-center relative">
                <div className="absolute left-1/2 top-10 -translate-x-1/2 w-1 h-20 bg-border hidden md:block" />
                <div className="relative z-10 w-20 h-20 rounded-full bg-primary flex items-center justify-center mx-auto mb-4">
                  <span className="text-2xl font-bold text-primary-foreground">2</span>
                </div>
                <h3 className="text-xl font-bold mb-2">Bot Joins Meeting</h3>
                <p className="text-muted-foreground">Loopback joins as a participant, records audio, and captures the conversation.</p>
              </div>
              <div className="text-center relative">
                <div className="relative z-10 w-20 h-20 rounded-full bg-primary flex items-center justify-center mx-auto mb-4">
                  <span className="text-2xl font-bold text-primary-foreground">3</span>
                </div>
                <h3 className="text-xl font-bold mb-2">Get Notes & Actions</h3>
                <p className="text-muted-foreground">AI generates transcript, summary, notes, and action items. Search everything instantly.</p>
              </div>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="bg-primary py-24 px-4 text-center">
          <div className="container mx-auto max-w-2xl">
            <h2 className="text-4xl font-bold text-primary-foreground mb-4">Ready for better meeting notes?</h2>
            <p className="text-xl text-primary-foreground/80 mb-8">
              Join thousands of professionals who trust Loopback to capture every detail.
            </p>
            <Link href="/signup">
              <Button size="lg" variant="secondary" className="gap-2">
                Start Free - No Credit Card Required
                <ArrowRight className="h-4 w-4" />
              </Button>
            </Link>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t py-12 px-4 bg-background">
        <div className="container mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <Bot className="h-6 w-6 text-primary" />
            <span className="font-bold">Loopback</span>
          </div>
          <nav className="flex flex-wrap items-center justify-center gap-6 text-sm text-muted-foreground">
            <Link href="/privacy" className="hover:text-foreground">Privacy</Link>
            <Link href="/terms" className="hover:text-foreground">Terms</Link>
            <Link href="/security" className="hover:text-foreground">Security</Link>
            <Link href="/docs" className="hover:text-foreground">Docs</Link>
          </nav>
          <p className="text-sm text-muted-foreground">© 2025 Loopback. Built with local AI.</p>
        </div>
      </footer>
    </div>
  );
}