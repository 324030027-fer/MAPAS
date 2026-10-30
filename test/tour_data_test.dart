import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nullcore_maps/data/default_schedules.dart';
import 'package:nullcore_maps/data/tours/tours.dart';
import 'package:nullcore_maps/models/tour.dart';
import 'package:nullcore_maps/providers/map_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Medidas (ancho, alto) de un JPG o PNG leyendo solo su encabezado.
({int w, int h})? _imageSize(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  final Uint8List d = file.readAsBytesSync();
  if (d.length > 24 && d[0] == 0x89 && d[1] == 0x50) {
    final b = ByteData.sublistView(d);
    return (w: b.getUint32(16), h: b.getUint32(20));
  }
  var i = 2;
  while (i + 9 < d.length) {
    if (d[i] != 0xFF) {
      i++;
      continue;
    }
    final m = d[i + 1];
    if (m == 0xC0 || m == 0xC1 || m == 0xC2) {
      return (w: (d[i + 7] << 8) | d[i + 8], h: (d[i + 5] << 8) | d[i + 6]);
    }
    if (m == 0xD8 || m == 0x01 || (m >= 0xD0 && m <= 0xD7)) {
      i += 2;
      continue;
    }
    i += 2 + ((d[i + 2] << 8) | d[i + 3]);
  }
  return null;
}

void main() {
  test('los ids de los recorridos son únicos', () {
    final ids = kTours.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  for (final tour in kTours) {
    group('recorrido ${tour.id}', () {
      test('está bien armado (paradas, tramos y laboratorios)', () {
        expect(tour.validate(), isEmpty);
      });

      test('todos sus panoramas existen', () {
        final missing = [
          for (final s in tour.stops)
            if (!File(s.asset).existsSync()) '${s.id}: ${s.asset}',
          if (!File(tour.coverAsset).existsSync()) 'portada: ${tour.coverAsset}',
        ];
        expect(missing, isEmpty, reason: 'Faltan imágenes: $missing');
      });

      test('cada tramo tiene hotspot de ida y de vuelta', () {
        for (final stop in tour.stops) {
          for (final link in tour.stop(stop.id).hotspotLinks) {
            final back = tour.stop(link.targetId).hotspotLinks.any((l) => l.targetId == stop.id);
            expect(back, isTrue, reason: '${stop.id} → ${link.targetId} sin vuelta');
          }
        }
      });

      test('sus laboratorios tienen ficha y horarios', () async {
        SharedPreferences.setMockInitialValues({});
        final map = MapProvider();
        await Future<void>.delayed(const Duration(milliseconds: 200));
        for (final entry in tour.labs.entries) {
          final ref = entry.value;
          expect(
            map.findLabInfo(ref.locationId, ref.labName),
            isNotNull,
            reason: 'Falta la ficha "${ref.labName}" en ${ref.locationId} (MapProvider)',
          );
          final schedules = DefaultSchedules.all[ref.locationId] ?? const [];
          expect(
            schedules.any((s) => s.labName == ref.scheduleName),
            isTrue,
            reason: 'Faltan horarios "${ref.scheduleName}" en ${ref.locationId} (DefaultSchedules)',
          );
        }
      });

      // No falla: imprime un reporte de calidad de las imágenes del recorrido.
      test('reporte de calidad de imágenes (solo avisos)', () {
        final warnings = <String>[];
        for (final s in tour.stops) {
          final size = _imageSize(s.asset);
          if (size == null) continue;
          final aspect = size.w / size.h;
          if ((aspect - 2).abs() > 0.03) {
            warnings.add('${s.id} (${s.asset}): ${size.w}×${size.h}, no es 2:1 (se ve estirada)');
          }
          if (size.w < 3500) {
            warnings.add('${s.id} (${s.asset}): ${size.w}×${size.h}, resolución baja (ideal 4096×2048)');
          }
          if (size.w > 4200) {
            warnings.add('${s.id} (${s.asset}): ${size.w}×${size.h}, muy grande (ideal 4096×2048)');
          }
        }
        // ignore: avoid_print
        print(warnings.isEmpty
            ? '[${tour.id}] Imágenes sin avisos.'
            : '[${tour.id}] AVISOS DE IMÁGENES:\n  - ${warnings.join('\n  - ')}');
      });
    });
  }

  test('Tour.single arma un recorrido de una sola panorámica', () {
    final t = Tour.single(title: 'Prueba', asset: 'assets/E1.jpg');
    expect(t.validate(), isEmpty);
    expect(t.start.hotspotLinks, isEmpty);
  });
}
