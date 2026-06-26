import { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
      },
    ],
    sitemap: "https://smartspend.astronkar.in/sitemap.xml",
    host: "https://smartspend.astronkar.in",
  };
}