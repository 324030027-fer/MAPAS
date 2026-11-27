import 'package:flutter/material.dart';
import 'package:panorama/panorama.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/tour_utils.dart';
import '../data/rooms.dart';
import '../models/map_location.dart';
import '../models/room.dart';
import '../models/tour.dart';
import '../providers/auth_provider.dart';
import '../providers/map_provider.dart';
import '../providers/tour_overrides_provider.dart';
import '../widgets/lab_tour_widgets.dart';
import '../widgets/room_picker.dart';
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

  /// Rumbo inicial (grados) cuando no se llega por un tramo del recorrido.
  final double? initialYaw;

  /// Salón que se está viendo (acceso directo): muestra la barra para pasar
  /// al anterior/siguiente o elegir otro sin salir del visor.
  final Room? room;

  const PanoramaViewer({super.key, required this.tour, this.startId, this.initialYaw, this.room});

  @override
  State<PanoramaViewer> createState() => _PanoramaViewerState();
}

/// Elemento que se está acomodando en el editor (flecha o recuadro).
sealed class _EditTarget {}

class _LinkTarget extends _EditTarget {
  _LinkTarget(this.targetId);
  final String targetId;
  @override
  bool operator ==(Object o) => o is _LinkTarget && o.targetId == targetId;
  @override
  int get hashCode => targetId.hashCode;
}

class _RoomTarget extends _EditTarget {
  _RoomTarget(this.roomId);
  final String roomId;
  @override
  bool operator ==(Object o) => o is _RoomTarget && o.roomId == roomId;
  @override
  int get hashCode => roomId.hashCode;
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

  /// Salón resaltado (el elegido o el último recuadro tocado).
  String? _roomId;

  // Editor (solo admins): acomodar flechas y recuadros tocando la foto.
  bool _editing = false;
  _EditTarget? _target;

  @override
  void initState() {
    super.initState();
    _roomId = widget.room?.id;
    currentLocation = _tour.stop(widget.startId ?? _tour.startId);
    _labPanelOpen = _labs.containsKey(currentLocation.id);
    final firstLab = _labs[currentLocation.id];
    if (firstLab != null) _longitude = firstLab.wallYaw;
    if (widget.initialYaw != null) _longitude = widget.initialYaw!;
    // Si un admin ya acomodó el recuadro del salón, se mira hacia él.
    final room = widget.room;
    if (room != null) {
      final anchor = context.read<TourOverridesProvider>().roomAnchor(room.id);
      if (anchor != null) _longitude = anchor.yaw;
    }
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

  /// La parada con los rumbos ajustados por un admin (si los hay).
  MapLocation _adjusted(MapLocation loc, TourOverridesProvider o) {
    return loc.copyWith(
      hotspotLinks: [
        for (final l in loc.hotspotLinks)
          HotspotLink(targetId: l.targetId, yaw: o.linkYaw(_tour.id, loc.id, l.targetId) ?? l.yaw, pitch: l.pitch),
      ],
    );
  }

  Future<void> _navigateTo(String targetId) async {
    final fromId = currentLocation.id;
    final target = _tour.stop(targetId);
    await _fresh(target);
    if (!mounted) return;
    final screen = MediaQuery.of(context).size;
    final overrides = context.read<TourOverridesProvider>();
    // En un laboratorio se llega mirando a la pared donde va la ventana.
    final labRef = _labs[target.id];
    final view = labRef != null
        ? (yaw: labRef.wallYaw, zoom: 1.0)
        : arrivalView(_adjusted(target, overrides), fromId, screen.width / screen.height);
    setState(() {
      currentLocation = target;
      _longitude = view.yaw;
      _zoom = view.zoom;
      _target = null;
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

  /// Salones cuya puerta se ve en la parada actual.
  List<Room> _roomsHere() {
    if (_labs.containsKey(currentLocation.id)) return const [];
    final inTour = kRooms.where((r) => r.tourStopId != null && r.tourStopId == currentLocation.id && r.buildingId == _tour.mapLocationId);
    if (inTour.isNotEmpty) return inTour.toList();
    // Panorama suelto de un salón (sin recorrido).
    final room = widget.room;
    return room != null && room.tourStopId == null ? [room] : const [];
  }

  RoomAnchor _anchorOf(Room r, TourOverridesProvider o) => o.roomAnchor(r.id) ?? (yaw: r.initialYaw, pitch: kRoomTagPitch);

  // ---------------------------------------------------------------------------
  // Editor

  Future<void> _placeAt(double longitude, double latitude) async {
    final target = _target;
    if (!_editing || target == null) return;
    final overrides = context.read<TourOverridesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final yaw = normalizeYaw(longitude);
    try {
      switch (target) {
        case _LinkTarget(:final targetId):
          await overrides.setLinkYaw(_tour.id, currentLocation.id, targetId, yaw);
          messenger.showSnackBar(_snack('Flecha hacia "${_tour.stop(targetId).title}" guardada (${yaw.round()}°)'));
        case _RoomTarget(:final roomId):
          await overrides.setRoomAnchor(roomId, yaw, latitude);
          final name = kRooms.firstWhere((r) => r.id == roomId).name;
          messenger.showSnackBar(_snack('Recuadro de $name guardado (${yaw.round()}°)'));
      }
    } catch (_) {
      messenger.showSnackBar(_snack('No se pudo guardar. Revisa tu conexión o tus permisos de admin.', error: true));
    }
  }

  Future<void> _reset() async {
    final target = _target;
    if (target == null) return;
    final overrides = context.read<TourOverridesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (target) {
        case _LinkTarget(:final targetId):
          await overrides.resetLinkYaw(_tour.id, currentLocation.id, targetId);
        case _RoomTarget(:final roomId):
          await overrides.resetRoomAnchor(roomId);
      }
      messenger.showSnackBar(_snack('Se restableció la posición original'));
    } catch (_) {
      messenger.showSnackBar(_snack('No se pudo restablecer.', error: true));
    }
  }

  SnackBar _snack(String text, {bool error = false}) => SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.danger : null,
        duration: const Duration(seconds: 2),
      );

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final overrides = context.watch<TourOverridesProvider>();
    final isAdmin = context.watch<AuthProvider>().showAdminTools;
    final editing = _editing && isAdmin;
    final here = _adjusted(currentLocation, overrides);
    final labHere = _labInfoFor(currentLocation.id);
    final labRefHere = _labs[currentLocation.id];
    final roomsHere = _roomsHere();
    final selectedRoom = roomsHere.where((r) => r.id == _roomId).firstOrNull;

    final hotspots = <Hotspot>[
      for (final link in here.hotspotLinks)
        if (_labInfoFor(link.targetId) case final labInfo?)
          // Los laboratorios no llevan flecha: ventana flotante con resumen.
          Hotspot(
            latitude: kLabHotspotPitch,
            longitude: link.yaw,
            width: kLabHotspotWidth,
            height: kLabHotspotHeight,
            widget: LabHotspotCard(
              lab: labInfo,
              onEnter: editing
                  ? () => setState(() => _target = _LinkTarget(link.targetId))
                  : () => _navigateTo(link.targetId),
            ),
          )
        else
          Hotspot(
            latitude: kTourArrowPitch,
            longitude: link.yaw,
            width: 150,
            height: isImportantTourStop(_tour.stop(link.targetId)) || editing ? 132 : 104,
            widget: TourArrow(
              // En el editor todas llevan nombre para saber cuál es cuál.
              label: isImportantTourStop(_tour.stop(link.targetId)) || editing ? _tour.stop(link.targetId).title : null,
              selected: editing && _target == _LinkTarget(link.targetId),
              onTap: editing
                  ? () => setState(() => _target = _LinkTarget(link.targetId))
                  : () => _navigateTo(link.targetId),
            ),
          ),
      // Recuadro de cada salón junto a su puerta.
      for (final r in roomsHere)
        Hotspot(
          latitude: _anchorOf(r, overrides).pitch,
          longitude: _anchorOf(r, overrides).yaw,
          width: kRoomTagWidth,
          height: kRoomTagHeight,
          widget: RoomDoorTag(
            room: r,
            selected: r.id == _roomId,
            editing: editing && _target == _RoomTarget(r.id),
            onTap: () => setState(() {
              _roomId = r.id;
              if (editing) _target = _RoomTarget(r.id);
            }),
          ),
        ),
      if (labHere != null && labRefHere != null && kLabPanelOnWall)
        Hotspot(
          latitude: labRefHere.wallPitch,
          longitude: labRefHere.wallYaw,
          width: 310,
          height: 340,
          widget: LabDetailPanel(lab: labHere, blur: 0),
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
          child: const BackButton(color: Colors.white),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            currentLocation.title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        actions: [
          if (isAdmin)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: editing ? AppColors.admin : Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: editing ? 'Terminar ajustes' : 'Ajustar flechas y recuadros',
                icon: Icon(editing ? Icons.check_rounded : Icons.tune_rounded, color: Colors.white),
                onPressed: () => setState(() {
                  _editing = !_editing;
                  _target = null;
                }),
              ),
            ),
        ],
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
                  onTap: editing ? (lon, lat, _) => _placeAt(lon, lat) : null,
                  hotspots: hotspots,
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
                      onClose: () => setState(() => _labPanelOpen = false),
                    ),
                  ),
                ),
              ),
            ),
          if (editing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: _EditorPanel(
                  links: [for (final l in here.hotspotLinks) _tour.stop(l.targetId)],
                  rooms: roomsHere,
                  target: _target,
                  isOverridden: (t) => switch (t) {
                    _LinkTarget(:final targetId) => overrides.hasLinkOverride(_tour.id, currentLocation.id, targetId),
                    _RoomTarget(:final roomId) => overrides.hasRoomOverride(roomId),
                  },
                  onSelect: (t) => setState(() => _target = t),
                  onReset: _reset,
                ),
              ),
            )
          // Barra de salones mientras se está en la foto de un salón elegido.
          else if (selectedRoom != null && labHere == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Center(child: RoomSwitcherBar(room: selectedRoom)),
                ),
              ),
            )
          else if (labHere != null)
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

/// Panel inferior del editor: elegir qué acomodar y luego tocar la foto.
class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.links,
    required this.rooms,
    required this.target,
    required this.isOverridden,
    required this.onSelect,
    required this.onReset,
  });

  final List<MapLocation> links;
  final List<Room> rooms;
  final _EditTarget? target;
  final bool Function(_EditTarget) isOverridden;
  final ValueChanged<_EditTarget> onSelect;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final items = <(_EditTarget, IconData, String)>[
      for (final l in links) (_LinkTarget(l.id), Icons.navigation_rounded, l.title),
      for (final r in rooms) (_RoomTarget(r.id), Icons.label_rounded, r.name),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      constraints: const BoxConstraints(maxWidth: 640),
      decoration: BoxDecoration(
        color: const Color(0xF21B2230),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.admin.withValues(alpha: 0.7)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.admin, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ajustar esta foto',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              if (target != null && isOverridden(target!))
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Restablecer'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70, visualDensity: VisualDensity.compact),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            target == null
                ? '1. Elige una flecha o un recuadro (aquí o tocándolo en la foto).'
                : '2. Toca en la foto el punto exacto donde va. Se guarda para todos al instante.',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('Esta foto no tiene flechas ni salones.', style: TextStyle(color: Colors.white54, fontSize: 12.5))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (t, icon, label) in items)
                  ChoiceChip(
                    selected: t == target,
                    showCheckmark: false,
                    onSelected: (_) => onSelect(t),
                    avatar: Icon(icon, size: 16, color: t == target ? AppColors.onAccent : AppColors.accent),
                    label: Text(isOverridden(t) ? '$label  ✓' : label),
                    labelStyle: TextStyle(
                      color: t == target ? AppColors.onAccent : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                    selectedColor: AppColors.accent,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    side: BorderSide(color: t == target ? AppColors.accent : Colors.white24),
                    shape: const StadiumBorder(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
