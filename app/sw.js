/* REIOFFER app service worker: fast loads, works on weak signal, always fetches the newest version when online */
const V = 'reioffer-v1';
const SHELL = ['./', './index.html', './manifest.webmanifest', './icon-192.png', './icon-512.png', './apple-touch-icon.png'];
const CDN = /cdnjs\.cloudflare\.com|fonts\.(googleapis|gstatic)\.com/;
const LIVE = /script\.google(usercontent)?\.com|nominatim|photon\.komoot|arcgisonline|openstreetmap|formsubmit/;

self.addEventListener('install', e => { e.waitUntil(caches.open(V).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())); });
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== V).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const req = e.request; if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (LIVE.test(url.hostname)) return;                       // deal data, maps, geocoding: always live
  if (req.mode === 'navigate') {                              // the app page: newest when online, cached when not
    e.respondWith(fetch(req).then(r => { const cp = r.clone(); caches.open(V).then(c => c.put('./index.html', cp)); return r; })
      .catch(() => caches.match('./index.html')));
    return;
  }
  if (CDN.test(url.hostname) || url.origin === location.origin) { // fonts, map library, icons
    e.respondWith(caches.match(req).then(hit => hit || fetch(req).then(r => {
      if (r.ok || r.type === 'opaque') { const cp = r.clone(); caches.open(V).then(c => c.put(req, cp)); }
      return r;
    })));
  }
});
