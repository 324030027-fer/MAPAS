import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';
import 'package:provider/provider.dart';
import '../core/utils/tour_utils.dart';
import '../models/map_location.dart';
import '../providers/map_provider.dart';

class PanoramaViewer extends StatefulWidget {
  final MapLocation initialLocation;
  const PanoramaViewer({super.key, required this.initialLocation});
  
  @override
  State<PanoramaViewer> createState() => _PanoramaViewerState();
}

class _PanoramaViewerState extends State<PanoramaViewer> {
  late MapLocation currentLocation;

  // El panorama no se monta hasta que su imagen salió de la caché de Flutter
  // (ver _fresh): así siempre se carga de forma asíncrona.
  bool _ready = false;

  // Rumbo y zoom iniciales de la vista al llegar a una ubicación.
  double _longitude = 0;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    currentLocation = widget.initialLocation;
    _fresh(currentLocation).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    // Libera la imagen de la caché al salir del visor.
    AssetImage(currentLocation.assetImage360).evict();
    super.dispose();
  }

  /// Saca la imagen de la caché de imágenes de Flutter.
  ///
  /// Si una imagen ya está en caché, se entrega de forma síncrona y el paquete
  /// `panorama` la aplica antes de que la esfera esté en la escena: el
  /// panorama queda en blanco (con los hotspots visibles) al volver a una
  /// ubicación ya visitada. Con la imagen fuera de caché, la carga es
  /// asíncrona y se dibuja bien.
  Future<void> _fresh(MapLocation loc) => AssetImage(loc.assetImage360).evict();

  Future<void> _navigateTo(String targetId) async {
    final provider = Provider.of<MapProvider>(context, listen: false);
    final fromId = currentLocation.id;
    final target = provider.getTourLocationById(targetId);
    await _fresh(target);
    if (!mounted) return;
    final screen = MediaQuery.of(context).size;
    final view = arrivalView(target, fromId, screen.width / screen.height);
    setState(() {
      currentLocation = target;
      _longitude = view.yaw;
      _zoom = view.zoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context, listen: false);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8), 
          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), 
          child: const BackButton(color: Colors.white)
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
          decoration: BoxDecoration(
            color: Colors.black45, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: Colors.white24)
          ), 
          child: Text(
            currentLocation.title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)
          )
        ),
        centerTitle: true,
      ),
      body: !_ready
          ? const SizedBox.expand()
          : Panorama(
        
        key: ValueKey(currentLocation.assetImage360),
        longitude: _longitude,
        zoom: _zoom,
        minZoom: kTourMinZoom,
        animSpeed: 0.0, 
        sensitivity: 2.0,
        hotspots: currentLocation.hotspotLinks.map((link) {
          final linkedLoc = provider.getTourLocationById(link.targetId);
          return Hotspot(
            latitude: link.pitch, 
            longitude: link.yaw, 
            width: 90, 
            height: 90,
            widget: GestureDetector(
              onTap: () => _navigateTo(link.targetId),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                          blurRadius: 15
                        )
                      ]
                    ),
                    child: const Icon(Icons.arrow_upward_sharp, color: Color(0xFF6C63FF), size: 36),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24)
                    ),
                    child: Text(
                      "Ir a ${linkedLoc.title}",
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        child: Image.asset(currentLocation.assetImage360),
      ),
    );
  }
}
