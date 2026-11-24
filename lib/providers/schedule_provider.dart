import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/lab_schedule.dart';

/// Horarios de laboratorio por ubicación, guardados en Firestore
/// (`schedules/{idUbicación}` → `{labs: [...]}`).
///
/// Son información interna: las reglas solo dejan leerlos a cuentas
/// @upjr.edu.mx y escribirlos a admins. Para invitados la lista queda vacía.
/// Los cambios del admin llegan a todos en tiempo real.
class ScheduleProvider extends ChangeNotifier {
  final _col = FirebaseFirestore.instance.collection('schedules');

  Map<String, List<LabSchedule>> _schedulesByLocation = {};
  bool _loaded = false;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _dataSub;

  Map<String, List<LabSchedule>> get schedulesByLocation => _schedulesByLocation;
  bool get isLoaded => _loaded;

  ScheduleProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onUser);
  }

  void _onUser(User? user) {
    _dataSub?.cancel();
    _dataSub = null;
    if (user == null) {
      _schedulesByLocation = {};
      _loaded = true;
      notifyListeners();
      return;
    }
    _dataSub = _col.snapshots().listen(
      (snap) {
        _schedulesByLocation = {
          for (final doc in snap.docs)
            doc.id: ((doc.data()['labs'] as List?) ?? [])
                .map((e) => LabSchedule.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList(),
        };
        _loaded = true;
        notifyListeners();
      },
      // Sin permiso (cuenta no UPJR) o sin red: se queda sin horarios.
      onError: (_) {
        _schedulesByLocation = {};
        _loaded = true;
        notifyListeners();
      },
    );
  }

  Future<void> _save(String locationId) async {
    final labs = _schedulesByLocation[locationId];
    if (labs == null) {
      await _col.doc(locationId).delete();
    } else {
      await _col.doc(locationId).set({
        'labs': labs.map((l) => l.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  List<String> get locationIdsWithSchedules => _schedulesByLocation.keys.toList();

  bool hasSchedulesForLocation(String locationId) {
    final labs = _schedulesByLocation[locationId];
    return labs != null && labs.isNotEmpty;
  }

  List<LabSchedule> getSchedulesForLocation(String locationId) {
    return _schedulesByLocation[locationId] ?? [];
  }

  Future<void> setSchedulesForLocation(String locationId, List<LabSchedule> schedules) async {
    _schedulesByLocation[locationId] = schedules;
    notifyListeners();
    await _save(locationId);
  }

  Future<void> updateLabAt(String locationId, int labIndex, LabSchedule lab) async {
    final labs = List<LabSchedule>.from(getSchedulesForLocation(locationId));
    if (labIndex < 0 || labIndex >= labs.length) return;
    labs[labIndex] = lab;
    await setSchedulesForLocation(locationId, labs);
  }

  Future<void> addLab(String locationId, String labName) async {
    final labs = List<LabSchedule>.from(getSchedulesForLocation(locationId))
      ..add(LabSchedule(labName: labName, entries: []));
    await setSchedulesForLocation(locationId, labs);
  }

  Future<void> removeLab(String locationId, int labIndex) async {
    final labs = List<LabSchedule>.from(getSchedulesForLocation(locationId));
    if (labIndex < 0 || labIndex >= labs.length) return;
    labs.removeAt(labIndex);
    if (labs.isEmpty) {
      _schedulesByLocation.remove(locationId);
      notifyListeners();
      await _save(locationId);
    } else {
      await setSchedulesForLocation(locationId, labs);
    }
  }

  Future<void> ensureLocationExists(String locationId) async {
    if (!_schedulesByLocation.containsKey(locationId)) {
      await setSchedulesForLocation(locationId, []);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _dataSub?.cancel();
    super.dispose();
  }
}
