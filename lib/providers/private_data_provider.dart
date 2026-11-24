import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/contact.dart';

/// Encargado de un laboratorio (nombre + correo).
class LabStaff {
  const LabStaff(this.inCharge, this.contact);
  final String inCharge;
  final String contact;
}

/// Datos internos de la comunidad UPJR que viven en Firestore:
/// profesores (`teachers`), encargados de laboratorio (`labStaff`) y guías de
/// trámites (`guides`). Solo se cargan con una sesión UPJR; para invitados
/// todo queda vacío (y las reglas de Firestore tampoco dejarían leerlos).
class PrivateDataProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final List<StreamSubscription> _subs = [];
  StreamSubscription<User?>? _authSub;

  List<Contact> _teachers = [];
  Map<String, Map<String, LabStaff>> _labStaff = {}; // ubicación → lab → encargado
  Map<String, Map<String, dynamic>> _guides = {};
  bool _loaded = false;

  List<Contact> get teachers => _teachers;
  bool get loaded => _loaded;

  /// Encargado del laboratorio [labName] en la ubicación [locationId].
  LabStaff? labStaff(String locationId, String labName) => _labStaff[locationId]?[labName];

  /// Encargado de un laboratorio buscando solo por su nombre (son únicos).
  LabStaff? labStaffByName(String labName) {
    for (final byLab in _labStaff.values) {
      final s = byLab[labName];
      if (s != null) return s;
    }
    return null;
  }

  /// Datos de una guía (p. ej. 'constancias'); null si no hay.
  Map<String, dynamic>? guide(String id) => _guides[id];

  PrivateDataProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onUser);
  }

  void _clearSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _onUser(User? user) {
    _clearSubs();
    _teachers = [];
    _labStaff = {};
    _guides = {};
    _loaded = user == null;
    notifyListeners();
    if (user == null) return;

    void onError(Object _) {
      _loaded = true;
      notifyListeners();
    }

    _subs.add(_db.collection('teachers').orderBy('name').snapshots().listen((snap) {
      _teachers = [for (final d in snap.docs) Contact.fromMap(d.id, d.data())];
      _loaded = true;
      notifyListeners();
    }, onError: onError));

    _subs.add(_db.collection('labStaff').snapshots().listen((snap) {
      _labStaff = {
        for (final d in snap.docs)
          d.id: {
            for (final l in (d.data()['labs'] as List? ?? []).cast<Map>())
              l['name'] as String: LabStaff(l['inCharge'] as String? ?? '', l['contact'] as String? ?? ''),
          },
      };
      notifyListeners();
    }, onError: onError));

    _subs.add(_db.collection('guides').snapshots().listen((snap) {
      _guides = {for (final d in snap.docs) d.id: d.data()};
      notifyListeners();
    }, onError: onError));
  }

  @override
  void dispose() {
    _clearSubs();
    _authSub?.cancel();
    super.dispose();
  }
}
