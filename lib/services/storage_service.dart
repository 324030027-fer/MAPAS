import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_location.dart';

class StorageService {
  static const String _mapPointsKey = 'map_points';

  // Guardar lista de puntos
  static Future<void> saveMapPoints(List<MapLocation> points) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pointsJson = points.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_mapPointsKey, pointsJson);
  }

  // Cargar lista de puntos
  static Future<List<MapLocation>> loadMapPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? pointsJson = prefs.getStringList(_mapPointsKey);
    if (pointsJson == null) return [];
    return pointsJson.map((json) => MapLocation.fromJson(jsonDecode(json))).toList();
  }
}