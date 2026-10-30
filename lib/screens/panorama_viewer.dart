import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';
import 'package:provider/provider.dart';
import '../core/utils/tour_utils.dart';
import '../models/lab_schedule.dart';
import '../models/map_location.dart';
import '../models/tour.dart';
import '../providers/map_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/lab_tour_widgets.dart';
import '../widgets/tour_arrow.dart';

/// Dónde se muestra la ventana de información del laboratorio:
/// - true: anclada a la pared, en la dirección a la que se mira al entrar
///   (se mueve con el panorama y no tapa la vista).
/// - false: ventana fija al centro de la pantalla, con botón de cerrar.
const bool kLabPanelOnWall = true;

class PanoramaViewer extends StatefulWidget {
  /// Recorrido que se muestra (paradas, tramos y laboratorios).
  final Tour tour;

  /// Parada donde empieza; por defecto la inicial del recorrido.
  final String? startId;

  const PanoramaViewer({super.key, required this.tour, this.startId});
  
  @override
  State<PanoramaViewer> createState() => _PanoramaViewerState();
}

class _PanoramaViewerState extends State<PanoramaViewer> {
  late MapLocation currentLocation;

  Tour get _tour => widget.tour;
  Map<String, TourLabRef> get _labs => _tour.labs;

  // El panorama no se monta hasta que su imagen salió de la caché de Flutter
  // (ver _fresh): así siempre se carga de forma asíncrona.
  bool _ready = false;

  // Rumbo y zoom iniciales de la vista al llegar a una ubicación.
  double _longitude = 0;
  double _zoom = 1.0;

  // Ventana de información del laboratorio (solo dentro de un laboratorio).
  bool _labPanelOpen = false;

  @override
  void initState() {
    super.initState();
    currentLocation = _tour.stop(widget.startId ?? _tour.startId);
    _labPanelOpen = _labs.containsKey(currentLocation.id);
    final firstLab = _labs[currentLocation.id];
    if (firstLab != null) _longitude = firstLab.wallYaw;
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
    final fromId = currentLocation.id;
    final target = _tour.stop(targetId);
    await _fresh(target);
    if (!mounted) return;
    final screen = MediaQuery.of(context).size;
    // En un laboratorio se llega mirando a la pared donde va la ventana.
    final labRef = _labs[target.id];
    final view = labRef != null
        ? (yaw: labRef.wallYaw, zoom: 1.0)
        : arrivalView(target, fromId, screen.width / screen.height);
    setState(() {
      currentLocation = target;
      _longitude = view.yaw;
      _zoom = view.zoom;
      // Al entrar a un laboratorio se abre su ventana de información.
      _labPanelOpen = _labs.containsKey(target.id);
    });
  }

  /// Datos del laboratorio de una ubicación del recorrido (null si no lo es).
  LabInfo? _labInfoFor(String tourId) {
    final ref = _labs[tourId];
    if (ref == null) return null;
    return Provider.of<MapProvider>(context, listen: false).findLabInfo(ref.locationId, ref.labName);
  }

  /// Horarios del laboratorio de una ubicación del recorrido.
  List<LabSchedule> _labSchedulesFor(String tourId, ScheduleProvider schedules) {
    final ref = _labs[tourId];
    if (ref == null) return const [];
    return schedules.getSchedulesForLocation(ref.locationId).where((s) => s.labName == ref.scheduleName).toList();
  }

  @override
  Widget build(BuildContext context) {
    final schedules = context.watch<ScheduleProvider>();
    final labHere = _labInfoFor(currentLocation.id);
    // Panel anclado a la pared del laboratorio.
    final labRefHere = _labs[currentLocation.id];
    final wallHotspots = <Hotspot>[
      if (labHere != null && labRefHere != null && kLabPanelOnWall)
        Hotspot(
          latitude: labRefHere.wallPitch,
          longitude: labRefHere.wallYaw,
          width: 310,
          height: 430,
          widget: LabDetailPanel(
            lab: labHere,
            schedules: _labSchedulesFor(currentLocation.id, schedules),
            blur: 0,
          ),
        ),
    ];
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          !_ready
          ? const SizedBox.expand()
          : Panorama(
        
        key: ValueKey(currentLocation.assetImage360),
        longitude: _longitude,
        zoom: _zoom,
        minZoom: kTourMinZoom,
        animSpeed: 0.0, 
        sensitivity: 2.0,
        hotspots: currentLocation.hotspotLinks.map((link) {
          final linkedLoc = _tour.stop(link.targetId);
          // Los laboratorios no llevan flecha: muestran una ventana flotante
          // con resumen y la opción de entrar.
          final labInfo = _labInfoFor(link.targetId);
          if (labInfo != null) {
            return Hotspot(
              latitude: kLabHotspotPitch,
              longitude: link.yaw,
              width: kLabHotspotWidth,
              height: kLabHotspotHeight,
              widget: LabHotspotCard(lab: labInfo, onEnter: () => _navigateTo(link.targetId)),
            );
          }
          // Flecha pequeña sobre el piso; solo entradas y baños llevan nombre.
          final important = isImportantTourStop(linkedLoc);
          return Hotspot(
            latitude: kTourArrowPitch,
            longitude: link.yaw,
            width: important ? 130 : 84,
            height: important ? 112 : 84,
            widget: TourArrow(
              label: important ? linkedLoc.title : null,
              onTap: () => _navigateTo(link.targetId),
            ),
          );
        }).toList()
          ..addAll(wallHotspots),
        child: Image.asset(currentLocation.assetImage360),
      ),
          // Dentro de un laboratorio: ventana de información al centro y, si
          // se cierra, un botón para volver a abrirla.
          if (labHere != null && !kLabPanelOnWall && _labPanelOpen)
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 64, 16, 84),
                  child: Center(
                    child: LabDetailPanel(
                      lab: labHere,
                      schedules: _labSchedulesFor(currentLocation.id, schedules),
                      onClose: () => setState(() => _labPanelOpen = false),
                    ),
                  ),
                ),
              ),
            ),
          if (labHere != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!kLabPanelOnWall && !_labPanelOpen) ...[
                        LabInfoButton(onTap: () => setState(() => _labPanelOpen = true)),
                        const SizedBox(width: 10),
                      ],
                      // Vuelve al pasillo desde el que se entró.
                      if (currentLocation.hotspotLinks.isNotEmpty)
                        LabExitButton(onTap: () => _navigateTo(currentLocation.hotspotLinks.first.targetId)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
