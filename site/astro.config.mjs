import { defineConfig } from "astro/config";

export default defineConfig({
  site: process.env.PUBLIC_SITE_URL || "https://notification-macos.pages.dev",
  output: "static",
  build: {
    format: "directory",
    inlineStylesheets: "always"
  }
});
