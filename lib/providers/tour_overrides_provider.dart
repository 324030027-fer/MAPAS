import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/tour_utils.dart';

/// Ubicación de un recuadro de salón dentro de su panorama.
typedef RoomAnchor = ({double yaw, double pitch});

/// Ajustes de los recorridos 360° hechos por un admin desde el visor:
/// rumbo de cada flecha y posición del recuadro de cada salón.
///
/// Se guardan en Firestore (`tourOverrides`), así que llegan a todos
/// —también a invitados— en tiempo real y se conservan aunque se cierre la
/// app. Lo que no tenga ajuste usa el valor escrito en el código.
///
/// - `tourOverrides/{idRecorrido}` → `{links: {"A>B": rumbo}}`: rumbo dentro
///   de la parada A de la flecha que lleva a B.
/// - `tourOverrides/salones` → `{anchors: {idSalón: {yaw, pitch}}}`.
class TourOverridesProvider extends ChangeNotifier {
  TourOverridesProvider({bool syncWithFirestore = true}) : _sync = syncWithFirestore {
    if (_sync) _sub = _col.snapshots().listen(_apply, onError: (_) {});
  }

  static const roomsDoc = 'salones';

  final bool _sync;
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('tourOverrides');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  final Map<String, Map<String, double>> _links = {};
  final Map<String, RoomAnchor> _anchors = {};

  static String linkKey(String from, String to) => '$from>$to';

  void _apply(QuerySnapshot<Map<String, dynamic>> snap) {
    _links.clear();
    _anchors.clear();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (doc.id == roomsDoc) {
        final anchors = data['anchors'];
        if (anchors is Map) {
          for (final e in anchors.entries) {
            final v = e.value;
            if (v is Map && v['yaw'] is num) {
              _anchors[e.key as String] = (yaw: (v['yaw'] as num).toDouble(), pitch: (v['pitch'] as num?)?.toDouble() ?? 4);
            }
          }
        }
      } else {
        final links = data['links'];
        if (links is Map) {
          _links[doc.id] = {
            for (final e in links.entries)
              if (e.value is num) e.key as String: (e.value as num).toDouble(),
          };
        }
      }
    }
    notifyListeners();
  }

  /// Rumbo ajustado de la flecha de [from] hacia [to]; null si no hay ajuste.
  double? linkYaw(String tourId, String from, String to) => _links[tourId]?[linkKey(from, to)];

  /// Posición ajustada del recuadro del salón; null si no hay ajuste.
  RoomAnchor? roomAnchor(String roomId) => _anchors[roomId];

  bool hasLinkOverride(String tourId, String from, String to) => linkYaw(tourId, from, to) != null;
  bool hasRoomOverride(String roomId) => _anchors.containsKey(roomId);

  /// Guarda el rumbo de una flecha (solo admins: las reglas rechazan a los demás).
  Future<void> setLinkYaw(String tourId, String from, String to, double yaw) async {
    final value = double.parse(normalizeYaw(yaw).toStringAsFixed(1));
    (_links[tourId] ??= {})[linkKey(from, to)] = value;
    notifyListeners();
    if (!_sync) return;
    await _col.doc(tourId).set({
      'links': {linkKey(from, to): value},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetLinkYaw(String tourId, String from, String to) async {
    _links[tourId]?.remove(linkKey(from, to));
    notifyListeners();
    if (!_sync) return;
    await _col.doc(tourId).update({FieldPath(['links', linkKey(from, to)]): FieldValue.delete()});
  }

  /// Guarda dónde va el recuadro de un salón.
  Future<void> setRoomAnchor(String roomId, double yaw, double pitch) async {
    final a = (
      yaw: double.parse(normalizeYaw(yaw).toStringAsFixed(1)),
      pitch: double.parse(pitch.clamp(-60, 60).toStringAsFixed(1)),
    );
    _anchors[roomId] = a;
    notifyListeners();
    if (!_sync) return;
    await _col.doc(roomsDoc).set({
      'anchors': {
        roomId: {'yaw': a.yaw, 'pitch': a.pitch},
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> resetRoomAnchor(String roomId) async {
    _anchors.remove(roomId);
    notifyListeners();
    if (!_sync) return;
    await _col.doc(roomsDoc).update({FieldPath(['anchors', roomId]): FieldValue.delete()});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
