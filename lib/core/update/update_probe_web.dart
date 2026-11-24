import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Huella de la versión publicada: ETag o Last-Modified de main.dart.js,
/// pedido sin caché. Null si no hay red.
Future<String?> currentBuildTag() async {
  try {
    final res = await web.window
        .fetch('main.dart.js'.toJS, web.RequestInit(method: 'HEAD', cache: 'no-store'))
        .toDart;
    if (!res.ok) return null;
    return res.headers.get('etag') ?? res.headers.get('last-modified');
  } catch (_) {
    return null;
  }
}

/// Borra la caché del service worker y recarga la página.
Future<void> hardReload() async {
  try {
    final regs = await web.window.navigator.serviceWorker.getRegistrations().toDart;
    for (final r in regs.toDart) {
      await r.unregister().toDart;
    }
    final keys = await web.window.caches.keys().toDart;
    for (final k in keys.toDart) {
      await web.window.caches.delete(k.toDart).toDart;
    }
  } catch (_) {}
  web.window.location.reload();
}
