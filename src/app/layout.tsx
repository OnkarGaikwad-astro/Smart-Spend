import type { Metadata, Viewport } from "next";
import { DM_Sans, Space_Mono } from "next/font/google";
import "./globals.css";
import { cn } from "@/lib/utils";

const dmSans = DM_Sans({ subsets: ["latin"], variable: "--font-sans" });
const spaceMono = Space_Mono({ weight: ["400", "700"], subsets: ["latin"], variable: "--font-mono" });

export const metadata: Metadata = {
  metadataBase: new URL("https://smartspend.astronkar.in"),

  title: {
    default: "SmartSpend AI",
    template: "%s | SmartSpend AI",
  },

  applicationName: "SmartSpend AI",

  description:
    "AI-powered personal finance assistant for students. Track expenses, analyze spending, and receive intelligent financial insights.",
  manifest: "/manifest.json",
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/icon-192x192.png", type: "image/png", sizes: "192x192" },
      { url: "/icon-512x512.png", type: "image/png", sizes: "512x512" },
    ],
    shortcut: "/favicon.ico",
    apple: "/icon-192x192.png",
  },

  keywords: [
    "SmartSpend",
    "AI Finance",
    "Expense Tracker",
    "Budget Planner",
    "Student Finance",
    "Money Management",
    "Personal Finance",
    "Finance AI",
    "Onkar Gaikwad",
  ],

  openGraph: {
    title: "SmartSpend AI",
    description:
      "AI-powered personal finance assistant for students.",
    url: "https://smartspend.astronkar.in",
    siteName: "SmartSpend AI",
    locale: "en_US",
    type: "website",
  },

  twitter: {
    card: "summary_large_image",
    title: "SmartSpend AI",
    description:
      "AI-powered personal finance assistant for students.",
  },

  alternates: {
    canonical: "/",
  },
};

export const viewport: Viewport = {
  themeColor: "#FFFFFF",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={cn("light", "font-sans", dmSans.variable, spaceMono.variable)}>
      <body className={`${dmSans.className} min-h-screen text-[var(--color-text-main)] flex flex-col antialiased`}>
        {children}
      </body>
    </html>
  );
}
