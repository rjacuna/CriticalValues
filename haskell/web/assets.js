const CACHE = "criticalvalues-assets-v1";
const versions = {"crit.wasm": "79f1bdece738ed39a63243d929a7664c30fec1c8a5d885c2cb6e4b15cb45b82a", "flint.wasm": "f3a8ca9e9a5de4ad51838a0cd4d8823b158e8ab2a4e6125241d10e87bda1e9e8"};

// Content-addressed downloads survive GitHub Pages' short HTTP cache lifetime.
// CacheStorage is optional: privacy mode/quota failures keep normal fetch working.
export async function asset(name, fingerprint = versions[name], priority = "auto") {
  const url = new URL(name, import.meta.url);
  if (fingerprint) url.searchParams.set("v", fingerprint);
  let cache;
  if (fingerprint && globalThis.caches) {
    try {
      cache = await caches.open(CACHE);
      const hit = await cache.match(url.href);
      if (hit) return hit;
    } catch { /* storage unavailable */ }
  }
  const response = await fetch(url, {priority});
  if (cache && response.ok) cache.put(url.href, response.clone()).catch(() => {});
  return response;
}

// Call after the initial view is complete. Background transfers begin only
// after initial scripts/styles/images have loaded and the browser has painted.
export function afterInitialView(task) {
  const schedule = () => requestAnimationFrame(() => requestAnimationFrame(() => {
    const run = () => Promise.resolve().then(task).catch(() => {});
    if (globalThis.requestIdleCallback) requestIdleCallback(run, {timeout: 2000});
    else setTimeout(run, 200);
  }));
  if (document.readyState === "complete") schedule();
  else addEventListener("load", schedule, {once: true});
}
