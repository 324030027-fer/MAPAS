import 'package:flutter/material.dart';

class HotspotLink {
  final String targetId;
  final double yaw;
  final double pitch;

  HotspotLink({required this.targetId, this.yaw = 0.0, this.pitch = 0.0});

  Map<String, dynamic> toJson() => {'targetId': targetId, 'yaw': yaw, 'pitch': pitch};
  factory HotspotLink.fromJson(Map<String, dynamic> json) => HotspotLink(
        targetId: json['targetId'],
        yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0,
        pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      );
}

class LabInfo {
  final String name;
  final String description;
  final String inCharge;
  final String contact;
  final String imageThumbnail;
  final String? asset360;

  LabInfo({required this.name, required this.description, required this.inCharge, required this.contact, required this.imageThumbnail, this.asset360});

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'inCharge': inCharge,
        'contact': contact,
        'imageThumbnail': imageThumbnail,
        'asset360': asset360,
      };
  factory LabInfo.fromJson(Map<String, dynamic> json) => LabInfo(
        name: json['name'],
        description: json['description'],
        inCharge: json['inCharge'],
        contact: json['contact'],
        imageThumbnail: json['imageThumbnail'],
        asset360: json['asset360'],
      );
}

class CareerInfo {
  final String name;
  final List<LabInfo> labs;

  CareerInfo({required this.name, required this.labs});

  Map<String, dynamic> toJson() => {'name': name, 'labs': labs.map((e) => e.toJson()).toList()};
  factory CareerInfo.fromJson(Map<String, dynamic> json) => CareerInfo(
        name: json['name'],
        labs: (json['labs'] as List).map((e) => LabInfo.fromJson(e)).toList(),
      );
}

/// Resuelve el ícono por codePoint contra constantes conocidas, para que el
/// tree-shaking de íconos funcione en release (sin IconData dinámicos).
/// Íconos disponibles para los lugares del mapa (nombre visible → ícono).
/// Se guardan por codePoint; al leer se buscan aquí (deben ser constantes
/// para que Flutter conserve la fuente de íconos).
const Map<String, IconData> kLocationIcons = {
  'Lugar': Icons.place,
  'Edificio': Icons.apartment,
  'Administración': Icons.account_balance,
  'Biblioteca': Icons.local_library,
  'Aula': Icons.class_outlined,
  'Docencia': Icons.school,
  'Laboratorio': Icons.science,
  'Cómputo': Icons.computer,
  'Cafetería': Icons.restaurant,
  'Café': Icons.local_cafe,
  'Baños': Icons.wc,
  'Estacionamiento': Icons.local_parking,
  'Basquetbol': Icons.sports_basketball,
  'Futbol': Icons.sports_soccer,
  'Deportes': Icons.fitness_center,
  'Auditorio': Icons.theater_comedy,
  'Enfermería': Icons.local_hospital,
  'Información': Icons.info_outline,
  'Entrada': Icons.door_front_door,
  'Parada': Icons.directions_bus,
};

IconData _iconFromCodePoint(int? codePoint) {
  if (codePoint == null) return Icons.place;
  for (final icon in kLocationIcons.values) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.place;
}

class MapLocation {
  final String id;
  String title;
  String description;
  String category;
  double x;
  double y;
  String assetImage360;
  IconData icon;
  String features;
  List<String> equipmentImages;
  List<HotspotLink> hotspotLinks;
  List<CareerInfo> careers;

  MapLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.x,
    required this.y,
    required this.assetImage360,
    this.icon = Icons.place,
    this.features = "• Acceso Controlado",
    this.equipmentImages = const [],
    this.hotspotLinks = const [],
    this.careers = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'x': x,
        'y': y,
        'assetImage360': assetImage360,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'features': features,
        'equipmentImages': equipmentImages,
        'hotspotLinks': hotspotLinks.map((e) => e.toJson()).toList(),
        'careers': careers.map((e) => e.toJson()).toList(),
      };

  factory MapLocation.fromJson(Map<String, dynamic> json) {
    return MapLocation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      assetImage360: json['assetImage360'],
      icon: _iconFromCodePoint(json['iconCodePoint'] as int?),
      features: json['features'] ?? '',
      equipmentImages: List<String>.from(json['equipmentImages'] ?? const []),
      hotspotLinks: ((json['hotspotLinks'] ?? const []) as List).map((e) => HotspotLink.fromJson(e)).toList(),
      careers: ((json['careers'] ?? const []) as List).map((e) => CareerInfo.fromJson(e)).toList(),
    );
  }

  MapLocation copyWith({
    String? title,
    String? description,
    String? category,
    double? x,
    double? y,
    String? assetImage360,
    IconData? icon,
    String? features,
    List<String>? equipmentImages,
    List<HotspotLink>? hotspotLinks,
    List<CareerInfo>? careers,
  }) {
    return MapLocation(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      x: x ?? this.x,
      y: y ?? this.y,
      assetImage360: assetImage360 ?? this.assetImage360,
      icon: icon ?? this.icon,
      features: features ?? this.features,
      equipmentImages: equipmentImages ?? this.equipmentImages,
      hotspotLinks: hotspotLinks ?? this.hotspotLinks,
      careers: careers ?? this.careers,
    );
  }
}