// Cache static assets for offline access.
const CACHE_NAME = "uptimer-v1";
const ASSETS = ["/", "/icon.png", "/icon.svg"];

self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS)),
    );
});

self.addEventListener("fetch", (event) => {
    event.respondWith(
        caches
            .match(event.request)
            .then((cached) => cached || fetch(event.request)),
    );
});
