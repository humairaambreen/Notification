import { defineConfig } from "astro/config";

export default defineConfig({
  site: process.env.PUBLIC_SITE_URL || "https://notification-3tn.pages.dev",
  output: "static",
  build: {
    format: "directory"
  }
});
