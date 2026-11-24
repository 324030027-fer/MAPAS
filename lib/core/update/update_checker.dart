import 'dart:async';

import 'package:flutter/foundation.dart';

import 'update_probe_stub.dart' if (dart.library.js_interop) 'update_probe_web.dart' as probe;

/// Avisa cuando se publicó una versión nueva de la app web.
///
/// Cada pocos minutos consulta la huella (ETag / Last-Modified) de
/// `main.dart.js` en el servidor; si cambia respecto a la que había al abrir,
/// [updateAvailable] pasa a true y la app muestra el botón para recargar.
/// En Android/iOS/escritorio no hace nada.
class UpdateChecker {
  UpdateChecker._();
  static final instance = UpdateChecker._();

  final ValueNotifier<bool> updateAvailable = ValueNotifier(false);
  String? _baseline;
  Timer? _timer;

  void start({Duration every = const Duration(minutes: 5)}) {
    if (!kIsWeb || _timer != null) return;
    _check();
    _timer = Timer.periodic(every, (_) => _check());
  }

  Future<void> _check() async {
    final tag = await probe.currentBuildTag();
    if (tag == null) return;
    _baseline ??= tag;
    if (tag != _baseline) {
      updateAvailable.value = true;
      _timer?.cancel();
    }
  }

  /// Recarga la página saltándose la caché.
  void reload() => probe.hardReload();
}
