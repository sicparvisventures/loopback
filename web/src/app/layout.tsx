import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/sonner";
import { ThemeProvider } from "@/components/theme-provider";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "Loopback - AI Meeting Notes",
    template: "%s | Loopback",
  },
  description: "AI-powered meeting notes with transcription, action items, and search.",
  keywords: ["meeting notes", "transcription", "AI", "productivity", "action items"],
  authors: [{ name: "Loopback" }],
  creator: "Loopback",
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://loopback.ai",
    siteName: "Loopback",
    title: "Loopback - AI Meeting Notes",
    description: "AI-powered meeting notes with transcription, action items, and search.",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "Loopback",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Loopback - AI Meeting Notes",
    description: "AI-powered meeting notes with transcription, action items, and search.",
    images: ["/og-image.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`} suppressHydrationWarning>
      <body className="min-h-full flex flex-col bg-background text-foreground">
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          {children}
        </ThemeProvider>
        <Toaster position="bottom-right" richColors />
      </body>
    </html>
  );
}