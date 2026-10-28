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

  List<MapLocation> _getDefaultTourPoints() {
    return [
      MapLocation(id: 'E1', title: 'Entrada Trasera', description: '', category: 'Entrada', x: 0, y: 0, assetImage360: 'assets/E1.jpg',
        hotspotLinks: [HotspotLink(targetId: 'E2', yaw: 93), HotspotLink(targetId: 'E3', yaw: -87)]),
      MapLocation(id: 'E2', title: 'Esquina Derecha', description: '', category: 'Esquina', x: 0, y: 0, assetImage360: 'assets/E2.jpg',
        hotspotLinks: [HotspotLink(targetId: 'P1', yaw: 45), HotspotLink(targetId: 'E1', yaw: -45)]),
      MapLocation(id: 'P1', title: 'Pasillo 1', description: '', category: 'Pasillo', x: 0, y: 0, assetImage360: 'assets/P1.jpg',
        hotspotLinks: [HotspotLink(targetId: 'P3', yaw: 140), HotspotLink(targetId: 'E2', yaw: -85)]),
      MapLocation(id: 'P3', title: 'Pasillo Central', description: '', category: 'Pasillo', x: 0, y: 0, assetImage360: 'assets/P3.jpg',
        hotspotLinks: [HotspotLink(targetId: 'BH', yaw: 0), HotspotLink(targetId: 'P1', yaw: 180)]),
      MapLocation(id: 'BH', title: 'Baños Hombres', description: '', category: 'Baños H', x: 0, y: 0, assetImage360: 'assets/S2.jpg',
        hotspotLinks: [HotspotLink(targetId: 'EP', yaw: 37), HotspotLink(targetId: 'P3', yaw: -55)]),
      MapLocation(id: 'EP', title: 'Entrada Principal', description: '', category: 'Entrada', x: 0, y: 0, assetImage360: 'assets/S1.jpg',
        hotspotLinks: [HotspotLink(targetId: 'BM', yaw: 90), HotspotLink(targetId: 'BH', yaw: -85)]),
      MapLocation(id: 'BM', title: 'Baños Mujeres', description: '', category: 'Baños M', x: 0, y: 0, assetImage360: 'assets/S3.jpg',
        hotspotLinks: [HotspotLink(targetId: 'P2', yaw: 45), HotspotLink(targetId: 'EP', yaw: -45)]),
      MapLocation(id: 'P4', title: 'Pasillo 4', description: '', category: 'Pasillo', x: 0, y: 0, assetImage360: 'assets/P4.jpg',
        hotspotLinks: [HotspotLink(targetId: 'P2', yaw: 90), HotspotLink(targetId: 'BM', yaw: -90)]),
      MapLocation(id: 'P2', title: 'Pasillo 2', description: '', category: 'Pasillo', x: 0, y: 0, assetImage360: 'assets/P2.jpg',
        hotspotLinks: [HotspotLink(targetId: 'E3', yaw: 90), HotspotLink(targetId: 'P4', yaw: -90), HotspotLink(targetId: 'LT', yaw: -110)]),
      MapLocation(id: 'E3', title: 'Esquina Izquierda', description: '', category: 'Esquina', x: 0, y: 0, assetImage360: 'assets/E3.jpg',
        hotspotLinks: [HotspotLink(targetId: 'E1', yaw: 42), HotspotLink(targetId: 'P2', yaw: -45)]),
      MapLocation(id: 'LT', title: 'LAB TELEMATICA', description: '', category: 'Edificio', x: 0, y: 0, assetImage360: 'assets/pano_telematica.jpg',
        hotspotLinks: [HotspotLink(targetId: 'P2', yaw: -45)]),
    ];
  }
}