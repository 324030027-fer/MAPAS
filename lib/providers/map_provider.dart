import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/map_location.dart';

/// Pines y edificios del mapa.
///
/// La base son los lugares por defecto escritos aquí (información pública,
/// sirve también sin internet). Encima se aplican los cambios del admin
/// guardados en Firestore (`map/{id}`), que llegan a todos en tiempo real:
/// un documento reemplaza al lugar con ese id, agrega uno nuevo, o lo quita si
/// trae `deleted: true`. Lectura pública; escritura solo admins (reglas).
class MapProvider extends ChangeNotifier {
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('map');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<MapLocation> _mapPoints = [];
  MapLocation? _selectedMapLocation;

  List<MapLocation> get mapPoints => _mapPoints;
  MapLocation? get selectedMapLocation => _selectedMapLocation;

  /// [syncWithFirestore] en false deja solo los lugares por defecto (pruebas).
  MapProvider({bool syncWithFirestore = true}) {
    _mapPoints = _getDefaultMapPoints();
    if (syncWithFirestore) _sub = _col.snapshots().listen(_apply, onError: (_) {});
  }

  void _apply(QuerySnapshot<Map<String, dynamic>> snap) {
    final byId = {for (final l in _getDefaultMapPoints()) l.id: l};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['deleted'] == true) {
        byId.remove(doc.id);
      } else {
        try {
          byId[doc.id] = MapLocation.fromJson({...data, 'id': doc.id});
        } catch (_) {
          // Documento mal formado: se ignora y se queda el valor por defecto.
        }
      }
    }
    _mapPoints = byId.values.toList();
    final sel = _selectedMapLocation;
    if (sel != null) {
      _selectedMapLocation = _mapPoints.where((l) => l.id == sel.id).firstOrNull;
    }
    notifyListeners();
  }

  /// Guarda el lugar en Firestore sin encargados ni correos: eso es privado
  /// y vive en `labStaff`.
  Future<void> _write(MapLocation loc) {
    final json = loc.toJson();
    for (final career in (json['careers'] as List? ?? [])) {
      for (final lab in ((career as Map)['labs'] as List? ?? [])) {
        (lab as Map)['inCharge'] = '';
        lab['contact'] = '';
      }
    }
    return _col.doc(loc.id).set({...json, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // CRUD (solo admins: las reglas rechazan a los demás)
  void addMapPoint(MapLocation location) {
    _mapPoints.add(location);
    notifyListeners();
    _write(location);
  }

  void updateMapPoint(MapLocation location) {
    final index = _mapPoints.indexWhere((l) => l.id == location.id);
    if (index == -1) return;
    _mapPoints[index] = location;
    notifyListeners();
    _write(location);
  }

  void removeMapPoint(String id) {
    _mapPoints.removeWhere((l) => l.id == id);
    if (_selectedMapLocation?.id == id) _selectedMapLocation = null;
    notifyListeners();
    _col.doc(id).set({'deleted': true, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void selectMapLocation(MapLocation? location) {
    _selectedMapLocation = location;
    notifyListeners();
  }

  /// Info de un laboratorio (encargado, descripción, foto) por ubicación del
  /// mapa y nombre. Null si no existe.
  LabInfo? findLabInfo(String locationId, String labName) {
    for (final loc in _mapPoints) {
      if (loc.id != locationId) continue;
      for (final career in loc.careers) {
        for (final lab in career.labs) {
          if (lab.name == labName) return lab;
        }
      }
    }
    return null;
  }

  // ==================== DATOS POR DEFECTO ====================
  List<MapLocation> _getDefaultMapPoints() {
    return [
      MapLocation(
        id: 'RECTORIA', title: 'RECTORÍA',
        description: 'Edificio que alberga a las máximas autoridades y la administración central.',
        category: 'Administración', x: 0.1016, y: 0.3836, assetImage360: '', icon: Icons.account_balance,
        features: "• Oficinas del Rector\n• Direcciones y Coordinaciones\n• Planeación",
        equipmentImages: ['assets/rectoria1.jpg','assets/EDIFICIOSRECT.jpg']
      ),
      MapLocation(
        id: 'BIBLIOTECA', title: 'BIBLIOTECA',
        description: 'Centro de recursos de información académica.',
        category: 'Estudio', x: 0.1195, y: 0.2830, assetImage360: '', icon: Icons.local_library,
        features: "• Acervo bibliográfico\n• Área digital\n• Préstamo de material",
        equipmentImages: ['assets/biblio1.png','assets/EDIFICIOSRECT.jpg']
      ),
      MapLocation(
        id: 'UD2', title: 'UD2 (UNIDAD DE DOCENCIA 2)',
        description: 'Enfocado en laboratorios y prácticas especializadas. Aquí encontrarás el laboratorio de Móviles.',
        category: 'Docencia', x: 0.2332, y: 0.8767, assetImage360: '', icon: Icons.class_outlined,
        features: "• Aulas\n• Laboratorios especializados\n• Espacios de trabajo",
        equipmentImages: ['assets/UD2.jpg', 'assets/UD21.jpg'],
        careers: [
          CareerInfo(
            name: "LABORATORIO DE MÓVILES",
            labs: [
              LabInfo(
                name: "LAB. DE TECNOLOGÍAS MÓVILES",
                description: "Laboratorio equipado para el desarrollo de aplicaciones móviles y telecomunicaciones.",
                inCharge: "",
                contact: "",
                imageThumbnail: "assets/moviles.jpg", // miniatura
                asset360: "assets/moviles.jpg",       // imagen 360
              ),
            ],
          )
        ],
      ),
      MapLocation(
        id: 'UD1', title: 'UD1 (UNIDAD DE DOCENCIA 1)',
        description: 'Enseñanza teórica y actividad académica cotidiana.',
        category: 'Docencia', x: 0.7996, y: 0.5377, assetImage360: '', icon: Icons.school,
        features: "• Aulas\n• Cubículos\n• Salas de cómputo",
        equipmentImages: ['assets/UD1.png','assets/UD1_IN.jpg']
      ),
      MapLocation(
        id: 'CAFETERIA', title: 'CAFETERÍA',
        description: 'Alimentación y descanso.',
        category: 'Servicios', x: 0.5999, y: 0.3271, assetImage360: '', icon: Icons.restaurant,
        features: "• Área de servicio\n• Comedor\n• Socialización",
        equipmentImages: ['assets/CAFE11.jpg','assets/CAFEPRIN.jpg']
      ),
      MapLocation(
        id: 'CANCHA', title: 'CANCHA DE USOS MÚLTIPLES',
        description: 'Deportes y eventos.',
        category: 'Deportes', x: 0.3594, y: 0.3046, assetImage360: '', icon: Icons.sports_basketball,
        features: "• Demarcación\n• Gradas\n• Actividades",
        equipmentImages: ['assets/CANCHA1.png', 'assets/CANCHA2.jpg']
      ),
      MapLocation(
        id: 'LT_MAP', title: 'LT (LABORATORIOS)',
        description: 'Edificio central de laboratorios de alta tecnología.',
        category: 'Laboratorio', x: 0.8000, y: 0.1365, assetImage360: '', icon: Icons.science,
        features: "• Acceso biométrico\n• Videovigilancia 24/7",
        equipmentImages: ['assets/LT1.jpg', 'assets/LT12.jpg'],
        careers: [
          CareerInfo(
            name: "ING. REDES Y TELECOMUNICACIONES / TI",
            labs: [
              LabInfo(
                name: "LAB. DE REDES",
                description: "Configuración de dispositivos de red, routing y switching.",
                inCharge: "",
                contact: "",
                imageThumbnail: "assets/redes.jpg",
                asset360: null,
              ),
              LabInfo(
                name: "LAB. DE ELECTRÓNICA",
                description: "Equipado con osciloscopios y estaciones de soldadura.",
                inCharge: "",
                contact: "",
                imageThumbnail: "assets/pano_electronica.jpg",
                asset360: "assets/pano_electronica.jpg",
              ),
              LabInfo(
                name: "LAB. DE TELEMÁTICA",
                description: "Laboratorio con 28 estaciones de trabajo.",
                inCharge: "",
                contact: "",
                imageThumbnail: "assets/pano_telematica.jpg",
                asset360: "assets/pano_telematica.jpg",
              ),
            ],
          )
        ],
      ),

      // ---------- BAÑOS ----------
      MapLocation(
        id: 'BANOS_RECTORIA', title: 'BAÑOS RECTORÍA',
        description: 'Sanitarios en la zona de Rectoría.',
        category: 'Baños', x: 0.0301, y: 0.3638, assetImage360: '', icon: Icons.wc,
        features: '• Baños de hombres y mujeres',
      ),
      MapLocation(
        id: 'BANOS_CAFETERIA', title: 'BAÑOS CAFETERÍA',
        description: 'Sanitarios junto a la cafetería.',
        category: 'Baños', x: 0.5430, y: 0.3530, assetImage360: '', icon: Icons.wc,
        features: '• Baños de hombres y mujeres',
      ),
      MapLocation(
        id: 'BANOS_LT', title: 'BAÑOS LT',
        description: 'Sanitarios en el edificio LT (laboratorios).',
        category: 'Baños', x: 0.8617, y: 0.3534, assetImage360: '', icon: Icons.wc,
        features: '• Baños de hombres y mujeres',
      ),
      MapLocation(
        id: 'BANOS_UD1', title: 'BAÑOS UD1',
        description: 'Sanitarios dentro de la Unidad de Docencia 1.',
        category: 'Baños', x: 0.7910, y: 0.5590, assetImage360: '', icon: Icons.wc,
        features: '• 2 baños en planta baja\n• 2 baños en planta alta',
      ),
      MapLocation(
        id: 'BANOS_UD2', title: 'BAÑOS UD2',
        description: 'Sanitarios dentro de la Unidad de Docencia 2.',
        category: 'Baños', x: 0.2680, y: 0.8880, assetImage360: '', icon: Icons.wc,
        features: '• 2 baños en planta baja\n• 2 baños en planta alta',
      ),

      // ---------- DEPORTES ----------
      MapLocation(
        id: 'CANCHA_FUTBOL', title: 'CANCHA DE FUTBOL (PASTO SINTÉTICO)',
        description: 'Cancha de futbol con pasto sintético.',
        category: 'Deportes', x: 0.4023, y: 0.5821, assetImage360: '', icon: Icons.sports_soccer,
        features: '• Pasto sintético\n• Futbol',
      ),

      // ---------- ESTACIONAMIENTO ----------
      MapLocation(
        id: 'ESTACIONAMIENTO_ALUMNOS', title: 'ESTACIONAMIENTO DE ALUMNOS',
        description: 'Estacionamiento para alumnos, junto al edificio LT.',
        category: 'Estacionamiento', x: 0.6123, y: 0.1455, assetImage360: '', icon: Icons.local_parking,
        features: '• Uso exclusivo de alumnos',
      ),
    ];
  }
}
