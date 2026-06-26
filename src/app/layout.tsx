import type { Metadata, Viewport } from "next";
import { DM_Sans, Space_Mono } from "next/font/google";
import "./globals.css";
import { cn } from "@/lib/utils";

const dmSans = DM_Sans({ subsets: ["latin"], variable: "--font-sans" });
const spaceMono = Space_Mono({ weight: ["400", "700"], subsets: ["latin"], variable: "--font-mono" });

export const metadata: Metadata = {
  title: "SmartSpend AI",
  description: "AI-Powered Personal Finance Tracker for Students",
  manifest: "/manifest.json",
  metadataBase: new URL("https://smartspend.astronkar.in"),
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
