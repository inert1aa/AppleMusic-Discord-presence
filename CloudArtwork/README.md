# Optional cloud artwork service

This folder contains a Cloudflare Worker that accepts JPEG cover art from Music Presence and serves it via stable, public HTTPS URLs. This is **not automatically deployed** by building the IPA.

## Setup

1. Create a Cloudflare account and an R2 bucket (R2 may require billing setup; free usage is subject to Cloudflare's current limits).
2. Create a Worker, paste `worker.js`, and bind the R2 bucket as `COVERS`.
3. Set a long random Worker secret named `UPLOAD_TOKEN`.
4. Deploy the Worker and copy its HTTPS address.
5. In Music Presence, select **Cloud**, enter `https://YOUR-WORKER.workers.dev/upload`, enter the same upload token, and save.

The app uploads the current song's embedded cover as JPEG. The Worker validates the upload, hashes the bytes, deduplicates them in R2, and returns `https://YOUR-WORKER.workers.dev/covers/HASH.jpg`. The app checks the returned image before sending the URL to Discord.

**Security:** Anyone with a public cover URL can see that image. Never use this service for private photos. Keep the upload token private; the current iOS prototype stores its configuration in app preferences, not the iOS Keychain, so use a dedicated token and rotate it if compromised. Consider rate limiting and quotas before public deployment. No album audio is uploaded. Discord still controls Rich Presence rendering, so no image host can guarantee artwork display.

If you don't deploy a Worker, keep using **Catbox**, the default. Existing working covers remain cached.
