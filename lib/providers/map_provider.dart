import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_location.dart';
class MapProvider extends ChangeNotifier {
  List<MapLocation> _mapPoints = [];
  List<MapLocation> _tourPoints = [];
  MapLocation? _selectedMapLocation;

  List<MapLocation> get mapPoints => _mapPoints;
  List<MapLocation> get tourPoints => _tourPoints;
  MapLocation? get selectedMapLocation => _selectedMapLocation;

  MapProvider() {
    _loadMapPoints();
    _initTourPoints();
  }

  // ==================== PERSISTENCIA ====================
  Future<void> _saveMapPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = _mapPoints.map((loc) => jsonEncode(loc.toJson())).toList();
    await prefs.setStringList('mapPoints', jsonList);
  }

  Future<void> _loadMapPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonList = prefs.getStringList('mapPoints');
    if (jsonList != null && jsonList.isNotEmpty) {
      _mapPoints = jsonList.map((jsonStr) => MapLocation.fromJson(jsonDecode(jsonStr))).toList();
    } else {
      _mapPoints = _getDefaultMapPoints();
      await _saveMapPoints();
    }
    notifyListeners();
  }

  // CRUD
  void addMapPoint(MapLocation location) {
    _mapPoints.add(location);
    _saveMapPoints();
    notifyListeners();
  }

  void updateMapPoint(MapLocation location) {
    final index = _mapPoints.indexWhere((l) => l.id == location.id);
    if (index != -1) {
      _mapPoints[index] = location;
      _saveMapPoints();
      notifyListeners();
    }
  }

  void removeMapPoint(String id) {
    _mapPoints.removeWhere((l) => l.id == id);
    if (_selectedMapLocation?.id == id) _selectedMapLocation = null;
    _saveMapPoints();
    notifyListeners();
  }

  void selectMapLocation(MapLocation? location) {
    _selectedMapLocation = location;
    notifyListeners();
  }

  // Tour points
  void _initTourPoints() {
    _tourPoints = _getDefaultTourPoints();
  }

  MapLocation getTourLocationById(String id) {
    return _tourPoints.firstWhere((loc) => loc.id == id, orElse: () => _tourPoints.first);
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
                inCharge: "Ing. Miguel Arreguin Juárez",
                contact: "marreguin@upjr.edu.mx",
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
                inCharge: "Ing. Erick Fernando Montecillo Olivares",
                contact: "emontecillo@upjr.edu.mx",
                imageThumbnail: "assets/redes.jpg",
                asset360: null,
              ),
              LabInfo(
                name: "LAB. DE ELECTRÓNICA",
                description: "Equipado con osciloscopios y estaciones de soldadura.",
                inCharge: "Ing. Erick Fernando Montecillo Olivares",
                contact: "emontecillo@upjr.edu.mx",
                imageThumbnail: "assets/pano_electronica.jpg",
                asset360: "assets/pano_electronica.jpg",
              ),
              LabInfo(
                name: "LAB. DE TELEMÁTICA",
                description: "Laboratorio con 28 estaciones de trabajo.",
                inCharge: "Ing. Erick Fernando Montecillo Olivares",
                contact: "emontecillo@upjr.edu.mx",
                imageThumbnail: "assets/pano_telematica.jpg",
                asset360: "assets/pano_telematica.jpg",
              ),
            ],
          )
        ],
      ),
    ];
  }

  // Ubicaciones del recorrido 360° del LT: (id, título, categoría, panorama).
  static const _tourNodes = <(String, String, String, String)>[
    ('E1', 'Entrada Trasera', 'Entrada', 'assets/E1.jpg'),
    ('E2', 'Esquina Derecha', 'Esquina', 'assets/E2.jpg'),
    ('P1', 'Pasillo 1', 'Pasillo', 'assets/P1.jpg'),
    ('P3', 'Pasillo Central', 'Pasillo', 'assets/P3.jpg'),
    ('BH', 'Baños Hombres', 'Baños H', 'assets/S2.jpg'),
    ('EP', 'Entrada Principal', 'Entrada', 'assets/S1.jpg'),
    ('BM', 'Baños Mujeres', 'Baños M', 'assets/S3.jpg'),
    ('P4', 'Pasillo 4', 'Pasillo', 'assets/P4.jpg'),
    ('P2', 'Pasillo 2', 'Pasillo', 'assets/P2.jpg'),
    ('E3', 'Esquina Izquierda', 'Esquina', 'assets/E3.jpg'),
    ('LT', 'LAB TELEMATICA', 'Edificio', 'assets/pano_telematica.jpg'),
  ];

  // Tramos del recorrido, declarados una sola vez: (A, rumbo en A hacia B,
  // B, rumbo en B hacia A). El rumbo (yaw, en grados) es la dirección dentro
  // de la panorámica de cada extremo; el hotspot de ida y el de vuelta se
  // generan juntos, así avanzar y retroceder siempre son coherentes.
  //
  // Orden (perímetro del edificio, en un solo sentido). Derecha/Izquierda se
  // ven desde la entrada trasera: el ala izquierda del mapa (E2, P1, P3) baja
  // hasta BH, pasa por la entrada principal (EP) y sube por el ala derecha
  // (BM, P4, P2 con acceso a LT) hasta E3:
  // E1 → E2 → P1 → P3 → BH → EP → BM → P4 → P2 → E3 → E1
  static const _tourEdges = <(String, double, String, double)>[
    ('E1', 93, 'E2', -45),
    ('E2', 45, 'P1', -85),
    ('P1', 140, 'P3', 180),
    ('P3', 0, 'BH', -55),
    ('BH', 37, 'EP', -85),
    ('EP', 90, 'BM', -45),
    ('BM', 45, 'P4', -90),
    ('P4', 90, 'P2', -90),
    ('P2', 90, 'E3', -45),
    ('E3', 42, 'E1', -87),
    // Ramal al laboratorio (siempre al final de los enlaces del pasillo).
    ('P2', -110, 'LT', -45),
  ];

  List<MapLocation> _getDefaultTourPoints() {
    final links = <String, List<HotspotLink>>{};
    for (final (a, yawA, b, yawB) in _tourEdges) {
      (links[a] ??= []).add(HotspotLink(targetId: b, yaw: yawA));
      (links[b] ??= []).add(HotspotLink(targetId: a, yaw: yawB));
    }
    return [
      for (final (id, title, category, asset) in _tourNodes)
        MapLocation(
          id: id,
          title: title,
          description: '',
          category: category,
          x: 0,
          y: 0,
          assetImage360: asset,
          hotspotLinks: links[id] ?? const [],
        ),
    ];
  }
}
