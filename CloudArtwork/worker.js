// Cloudflare Worker + R2. Deploy separately; never put R2 credentials in the IPA.
// Configure an R2 binding named COVERS and a secret UPLOAD_TOKEN.
// Cloudflare Workers' public URL is used only for image retrieval.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "GET" && /^\/covers\/[a-f0-9]{64}\.jpg$/.test(url.pathname)) {
      const key = url.pathname.slice("/covers/".length);
      const object = await env.COVERS.get(key);
      if (!object) return new Response("Not found", { status: 404 });
      return new Response(object.body, {
        headers: {
          "Content-Type": "image/jpeg",
          "Cache-Control": "public, max-age=31536000, immutable",
          "X-Content-Type-Options": "nosniff"
        }
      });
    }
    if (request.method !== "PUT" || url.pathname !== "/upload")
      return new Response("Not found", { status: 404 });
    if (!env.UPLOAD_TOKEN || request.headers.get("Authorization") !== "Bearer " + env.UPLOAD_TOKEN)
      return new Response("Unauthorized", { status: 401 });
    if (!request.headers.get("Content-Type")?.startsWith("image/jpeg"))
      return new Response("JPEG only", { status: 415 });
    const length = Number(request.headers.get("Content-Length") || 0);
    if (length > 5_000_000) return new Response("Too large", { status: 413 });
    const bytes = await request.arrayBuffer();
    if (bytes.byteLength < 4 || bytes.byteLength > 5_000_000)
      return new Response("Invalid size", { status: 413 });
    const view = new Uint8Array(bytes);
    if (view[0] !== 0xff || view[1] !== 0xd8 || view[2] !== 0xff)
      return new Response("Invalid JPEG", { status: 415 });
    const digest = await crypto.subtle.digest("SHA-256", bytes);
    const hash = [...new Uint8Array(digest)].map(b => b.toString(16).padStart(2, "0")).join("");
    const key = hash + ".jpg";
    if (!(await env.COVERS.head(key))) {
      await env.COVERS.put(key, bytes, { httpMetadata: { contentType: "image/jpeg" } });
    }
    return Response.json({ url: new URL("/covers/" + key, url).toString() });
  }
};
