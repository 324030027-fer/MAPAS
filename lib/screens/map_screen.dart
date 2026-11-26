import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../data/building_outlines.dart';
import '../data/floor_plans.dart';
import '../data/rooms.dart';
import '../models/map_location.dart';
import '../providers/auth_provider.dart';
import '../providers/map_provider.dart';
import '../widgets/admin_badge.dart';
import '../widgets/building_outline_painter.dart';
import '../widgets/glass.dart';
import '../widgets/grid_painter.dart';
import '../widgets/map_onboarding_overlay.dart';
import '../widgets/map_widgets.dart';
import '../widgets/responsive.dart';
import '../widgets/room_picker.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static const double _maxZoom = 5.0;
  // A partir de este zoom se muestran los nombres de todos los pines.
  static const double _labelsZoom = 1.5;

  final TransformationController _transformer = TransformationController();
  final GlobalKey _viewerKey = GlobalKey();
  late final AnimationController _zoomAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
  late final Animation<double> _zoomCurve = CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic);
  Matrix4Tween? _zoomTween;

  // Tarjeta emergente al pasar el mouse por un pin.
  final GlobalKey _stackKey = GlobalKey();
  final Map<String, GlobalKey> _markerKeys = {};
  String? _hoverId;
  Offset _hoverTop = Offset.zero; // parte alta del pin (coords. del Stack)
  Offset _hoverBottom = Offset.zero; // parte baja del icono
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _sidePanelScroll = ScrollController();
  String _searchQuery = '';
  String? _categoryFilter;

  // Siluetas de edificios: brillo que parpadea, edificio bajo el mouse y
  // edificio "abierto" (acercado, mostrando sus puntos interiores).
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  String? _hoverBuildingId;
  String? _focusId;
  int _floor = 0; // planta mostrada del edificio abierto
  FloorZone? _zone; // zona tocada en el plano

  bool get _isFiltering =>
      (_categoryFilter != null && _categoryFilter != 'Todos') || _searchQuery.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Al alejarse del edificio abierto, se "cierra".
    _transformer.addListener(() {
      if (_focusId != null && !_zoomAnim.isAnimating && _transformer.value.getMaxScaleOnAxis() < 1.2) {
        setState(() => _focusId = null);
      }
    });
    _zoomAnim.addListener(() {
      final tween = _zoomTween;
      if (tween != null) _transformer.value = tween.evaluate(_zoomCurve);
    });
  }

  void _animateTo(Matrix4 target) {
    if (_hoverId != null) setState(() => _hoverId = null);
    _zoomTween = Matrix4Tween(begin: _transformer.value, end: target);
    _zoomAnim.forward(from: 0);
  }

  /// Acerca/aleja manteniendo fijo el centro de la vista y sin salir del mapa.
  void _zoomBy(double factor) {
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final size = box.size;
    final m = _transformer.value;
    final s = m.getMaxScaleOnAxis();
    final ns = (s * factor).clamp(1.0, _maxZoom);
    if (ns == s) return;
    final k = ns / s;
    final t = m.getTranslation();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final tx = (cx - (cx - t.x) * k).clamp(size.width - size.width * ns, 0.0);
    final ty = (cy - (cy - t.y) * k).clamp(size.height - size.height * ns, 0.0);
    _animateTo(Matrix4(ns, 0, 0, 0, 0, ns, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1));
  }

  void _resetZoom() {
    setState(() => _focusId = null);
    _animateTo(Matrix4.identity());
  }

  /// Acerca la vista al contorno del edificio y muestra sus puntos interiores.
  void _focusBuilding(String id) {
    final outline = kBuildingOutlines[id];
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (outline == null || box == null) return;
    final w = box.size.width, h = box.size.height;
    final side = w < h ? w : h;
    final off = Offset((w - side) / 2, (h - side) / 2);
    final r = outlineBounds(outline);
    final rect = Rect.fromLTRB(off.dx + r.left * side, off.dy + r.top * side,
        off.dx + r.right * side, off.dy + r.bottom * side);
    // Cabe entre los filtros (arriba) y la barra del edificio (abajo).
    final sx = w * 0.6 / rect.width, sy = h * 0.38 / rect.height;
    final ns = (sx < sy ? sx : sy).clamp(1.5, _maxZoom);
    final tx = (w / 2 - rect.center.dx * ns).clamp(w - w * ns, 0.0);
    final ty = (h * 0.47 - rect.center.dy * ns).clamp(h - h * ns, 0.0);
    setState(() {
      _focusId = id;
      _hoverBuildingId = null;
      _floor = 0;
      _zone = null;
    });
    context.read<MapProvider>().selectMapLocation(null);
    _animateTo(Matrix4(ns, 0, 0, 0, 0, ns, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1));
  }

  /// Zonas de una planta como indicadores pequeños (mismo estilo que los
  /// pines) en el centro de cada zona, a tamaño fijo en pantalla.
  Widget _buildFloorZones(Floor floor, Rect bounds, Size size, double scale) {
    const d = 30.0; // diámetro del indicador
    return Stack(
      clipBehavior: Clip.none,
      children: floor.zones.map((z) {
        final selected = identical(z, _zone);
        final cx = (bounds.left + z.pinPoint.dx * bounds.width) * size.width;
        final cy = (bounds.top + z.pinPoint.dy * bounds.height) * size.height;
        final color = selected ? AppColors.highlight : AppColors.primary;
        return Positioned(
          left: cx - 60,
          top: cy - d / 2,
          width: 120,
          height: 60,
          child: Transform.scale(
            scale: 1 / scale,
            alignment: const Alignment(0, -0.5), // centro del círculo
            child: Column(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _zone = selected ? null : z),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)],
                      ),
                      child: Icon(z.kind.icon, color: AppColors.onAccent, size: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                IgnorePointer(child: _SubtleLabel(z.name)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Lista de lugares visibles (barra lateral de PC). Un edificio con
  /// silueta se abre; los demás muestran su ficha.
  Widget _buildPlacesList(MapProvider provider, List<MapLocation> visible, bool isDark) {
    final places = visible.where((l) => !kInteriorParent.containsKey(l.id) || _isFiltering).toList()
      ..sort((a, b) => (kShortNames[a.id] ?? a.title).compareTo(kShortNames[b.id] ?? b.title));
    if (places.isEmpty) {
      return Text('Sin resultados', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45));
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, i) {
        final l = places[i];
        final active = l.id == _focusId || l.id == provider.selectedMapLocation?.id;
        return Material(
          color: active ? AppColors.primary.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (kBuildingOutlines.containsKey(l.id)) {
                _focusBuilding(l.id);
              } else {
                provider.selectMapLocation(l);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Icon(l.icon, size: 20, color: active ? AppColors.accent : (isDark ? Colors.white70 : AppColors.textSecondaryLight)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kShortNames[l.id] ?? l.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          l.category,
                          style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondaryLight, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _buildingAt(Offset local, Size size, Map<String, List<Offset>> outlines) {
    final q = Offset(local.dx / size.width, local.dy / size.height);
    for (final e in outlines.entries) {
      if (outlineContains(e.value, q)) return e.key;
    }
    return null;
  }

  /// Laboratorios del edificio abierto como puntos flotantes dentro de él.
  List<MapLocation> _labPoints(MapLocation building) {
    final outline = kBuildingOutlines[building.id];
    final labs = building.careers.expand((c) => c.labs).toList();
    if (outline == null || labs.isEmpty) return [];
    final r = outlineBounds(outline);
    return [
      for (var i = 0; i < labs.length; i++)
        MapLocation(
          id: '${building.id}_LAB_$i',
          title: labs[i].name,
          description: labs[i].description,
          category: 'Laboratorio',
          x: r.left + r.width * (i + 1) / (labs.length + 1),
          y: r.top + r.height * (i.isEven ? 0.35 : 0.6),
          assetImage360: '',
          icon: Icons.science,
          equipmentImages: [labs[i].imageThumbnail],
        ),
    ];
  }

  void _onPinEnter(MapLocation loc) {
    final markerBox = _markerKeys[loc.id]?.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (markerBox == null || stackBox == null || !markerBox.attached) return;
    setState(() {
      _hoverId = loc.id;
      _hoverTop = stackBox.globalToLocal(markerBox.localToGlobal(const Offset(20, 0)));
      _hoverBottom = stackBox.globalToLocal(markerBox.localToGlobal(const Offset(20, 40)));
    });
  }

  void _onPinExit(String id) {
    if (_hoverId == id) setState(() => _hoverId = null);
  }

  Widget? _buildHoverCard(MapProvider provider, BuildContext context) {
    final id = _hoverId;
    // Con la hoja abierta sobre ese mismo pin no hace falta la tarjeta.
    if (id == null || provider.selectedMapLocation?.id == id) return null;
    final matches = provider.mapPoints.where((l) => l.id == id);
    if (matches.isEmpty) return null;

    const cardW = 250.0;
    const cardH = 215.0;
    final screenW = MediaQuery.of(context).size.width;
    final headerBottom = MediaQuery.of(context).padding.top + 190;

    final left = (_hoverTop.dx - cardW / 2).clamp(12.0, (screenW - cardW - 12).clamp(12.0, double.infinity));
    final above = _hoverTop.dy - cardH - 10;
    final top = above >= headerBottom ? above : _hoverBottom.dy + 12;

    return Positioned(
      left: left,
      top: top,
      width: cardW,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(id),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 140),
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, (1 - t) * 6), child: child),
          ),
          child: _PinPreviewCard(location: matches.first),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    _zoomAnim.dispose();
    _searchController.dispose();
    _sidePanelScroll.dispose();
    _transformer.dispose();
    super.dispose();
  }

  List<MapLocation> _visiblePoints(MapProvider provider) {
    return provider.mapPoints.where((loc) {
      final matchesCategory =
          _categoryFilter == null || _categoryFilter == 'Todos' || loc.category == _categoryFilter;
      if (!matchesCategory) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return loc.title.toLowerCase().contains(q) ||
          loc.description.toLowerCase().contains(q) ||
          loc.category.toLowerCase().contains(q);
    }).toList();
  }

  List<String> _categories(MapProvider provider) {
    final set = provider.mapPoints.map((e) => e.category).toSet().toList()..sort();
    return ['Todos', ...set];
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final auth = context.watch<AuthProvider>();
    final visible = _visiblePoints(mapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    final hoverCard = _buildHoverCard(mapProvider, context);

    // En pantallas anchas: cabecera compacta a la izquierda, barras inferiores
    // centradas con ancho fijo y la ficha del lugar como panel lateral.
    final screenW = MediaQuery.sizeOf(context).width;
    final wide = screenW >= Breakpoints.tablet;
    final sidePanel = wide && mapProvider.selectedMapLocation != null;
    const panelW = 420.0;
    const barMaxW = 560.0;
    const sidebarW = 340.0;
    final mapLeft = wide ? sidebarW : 0.0; // el mapa ocupa lo que deja la barra
    final mapAreaW = screenW - mapLeft - (sidePanel ? panelW + 16 : 0);
    final barSide = mapAreaW > barMaxW + 32 ? (mapAreaW - barMaxW) / 2 : 16.0;
    final barLeft = mapLeft + barSide;
    final barRight = screenW - mapLeft - mapAreaW + barSide;

    return Stack(
      key: _stackKey,
      fit: StackFit.expand,
      children: [
        // Relleno estático: el mismo mapa desenfocado cubre toda el área para
        // que no queden bandas vacías alrededor del mapa cuadrado.
        Positioned.fill(
          child: RepaintBoundary(
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Image.asset('assets/mapa_base.jpg', fit: BoxFit.cover, cacheWidth: 512),
              ),
            ),
          ),
        ),
        Positioned(
          left: mapLeft,
          top: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => mapProvider.selectMapLocation(null),
            // Mapa fijo: no se puede alejar ni sacar de los bordes; el zoom
            // solo acerca y el desplazamiento queda limitado al mapa.
            child: InteractiveViewer(
              key: _viewerKey,
              transformationController: _transformer,
              minScale: 1.0,
              maxScale: _maxZoom,
              boundaryMargin: EdgeInsets.zero,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.asset(
                            'assets/mapa_base.jpg',
                            fit: BoxFit.cover,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                divisions: 10,
                              ),
                            ),
                          ),
                          // Siluetas tocables de los edificios.
                          Positioned.fill(
                            child: ValueListenableBuilder<Matrix4>(
                              valueListenable: _transformer,
                              builder: (context, matrix, _) {
                                final size = Size(constraints.maxWidth, constraints.maxHeight);
                                final outlines = {
                                  for (final l in visible)
                                    if (kBuildingOutlines[l.id] != null) l.id: kBuildingOutlines[l.id]!,
                                };
                                return MouseRegion(
                                  cursor: _hoverBuildingId != null ? SystemMouseCursors.click : MouseCursor.defer,
                                  onHover: (e) {
                                    final id = _buildingAt(e.localPosition, size, outlines);
                                    if (id != _hoverBuildingId) setState(() => _hoverBuildingId = id);
                                  },
                                  onExit: (_) {
                                    if (_hoverBuildingId != null) setState(() => _hoverBuildingId = null);
                                  },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (d) {
                                      final id = _buildingAt(d.localPosition, size, outlines);
                                      if (id != null) {
                                        _focusBuilding(id);
                                      } else {
                                        mapProvider.selectMapLocation(null);
                                      }
                                    },
                                    child: CustomPaint(
                                      painter: BuildingOutlinePainter(
                                        outlines: outlines,
                                        pulse: _pulse,
                                        color: Colors.white,
                                        highlightColor: AppColors.accent,
                                        scale: matrix.getMaxScaleOnAxis().clamp(1.0, _maxZoom),
                                        hoverId: _hoverBuildingId,
                                        focusId: _focusId,
                                        glow: isDark ? 1.0 : 0.4,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Nombres discretos de los edificios (vista general).
                          if (_focusId == null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: ValueListenableBuilder<Matrix4>(
                                  valueListenable: _transformer,
                                  builder: (context, matrix, _) {
                                    final scale = matrix.getMaxScaleOnAxis().clamp(1.0, _maxZoom);
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        for (final l in visible)
                                          if (kBuildingOutlines[l.id] case final o?)
                                            Positioned(
                                              left: outlineBounds(o).center.dx * constraints.maxWidth - 70,
                                              top: outlineBounds(o).center.dy * constraints.maxHeight - 10,
                                              width: 140,
                                              height: 20,
                                              child: Transform.scale(
                                                scale: 1 / scale,
                                                child: Center(child: _SubtleLabel(kShortNames[l.id] ?? l.title)),
                                              ),
                                            ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          // Plano de la planta del edificio abierto.
                          if (_focusId != null && kFloorPlans.containsKey(_focusId))
                            Positioned.fill(
                              child: ValueListenableBuilder<Matrix4>(
                                valueListenable: _transformer,
                                builder: (context, matrix, _) => _buildFloorZones(
                                  kFloorPlans[_focusId]![_floor],
                                  outlineBounds(kBuildingOutlines[_focusId]!),
                                  Size(constraints.maxWidth, constraints.maxHeight),
                                  matrix.getMaxScaleOnAxis().clamp(1.0, _maxZoom),
                                ),
                              ),
                            ),
                          // Pines de tamaño constante en pantalla: al acercar el
                          // mapa se separan en lugar de crecer junto con él.
                          Positioned.fill(
                            child: ValueListenableBuilder<Matrix4>(
                              valueListenable: _transformer,
                              builder: (context, matrix, _) {
                                final scale = matrix.getMaxScaleOnAxis().clamp(1.0, _maxZoom);
                                final selectedId = mapProvider.selectedMapLocation?.id;
                                // El seleccionado va al final para quedar encima.
                                // Los edificios con silueta no llevan pin; los
                                // puntos interiores solo aparecen al abrir su
                                // edificio (o al filtrar/buscar).
                                final focused = _focusId == null
                                    ? null
                                    : mapProvider.mapPoints.where((l) => l.id == _focusId).firstOrNull;
                                final pins = [
                                  ...visible.where((l) {
                                    if (kBuildingOutlines.containsKey(l.id)) return false;
                                    final parent = kInteriorParent[l.id];
                                    // Con plano de plantas, las zonas ya los muestran.
                                    final inOpen = parent == _focusId && !kFloorPlans.containsKey(_focusId);
                                    return parent == null || inOpen || _isFiltering;
                                  }),
                                  if (focused != null) ..._labPoints(focused),
                                ];
                                final ordered = [
                                  ...pins.where((l) => l.id != selectedId),
                                  ...pins.where((l) => l.id == selectedId),
                                ];
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: ordered.map((loc) {
                                    return Positioned(
                                      left: (loc.x * constraints.maxWidth) - 20,
                                      top: (loc.y * constraints.maxHeight) - 20,
                                      width: 40,
                                      height: 48,
                                      child: Transform.scale(
                                        scale: 1 / scale,
                                        // Centro del icono (20 de 48 de alto).
                                        alignment: const Alignment(0, -0.1667),
                                        child: MouseRegion(
                                          onEnter: (_) => _onPinEnter(loc),
                                          onExit: (_) => _onPinExit(loc.id),
                                          child: KeyedSubtree(
                                            key: _markerKeys.putIfAbsent(loc.id, () => GlobalKey()),
                                            child: MapMarker(
                                              location: loc,
                                              isSelected: selectedId == loc.id,
                                              showLabel: scale >= _labelsZoom,
                                              onTap: () {
                                                setState(() => _hoverId = null);
                                                // Un laboratorio abre la ficha de su edificio.
                                                mapProvider.selectMapLocation(
                                                    loc.id.contains('_LAB_') && focused != null ? focused : loc);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // Controles de zoom
        Positioned(
          right: sidePanel ? panelW + 28 : 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: GlassContainer(
              radius: 22,
              blur: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ZoomButton(icon: Icons.add_rounded, tooltip: 'Acercar', onTap: () => _zoomBy(1.6), isDark: isDark),
                  _ZoomButton(icon: Icons.remove_rounded, tooltip: 'Alejar', onTap: () => _zoomBy(1 / 1.6), isDark: isDark),
                  _ZoomButton(icon: Icons.center_focus_strong_rounded, tooltip: 'Ver todo el mapa', onTap: _resetZoom, isDark: isDark),
                ],
              ),
            ),
          ),
        ),

        // Header + search
        Positioned(
          top: 0,
          left: 0,
          right: wide ? null : 0,
          bottom: wide ? 0 : null,
          width: wide ? sidebarW : null,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + (wide ? 20 : 8),
              bottom: 12,
              left: wide ? 20 : 16,
              right: wide ? 20 : 16,
            ),
            decoration: wide
                ? BoxDecoration(
                    color: bg.withValues(alpha: 0.86),
                    border: Border(right: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08))),
                  )
                : BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [bg.withValues(alpha: 0.55), bg.withValues(alpha: 0)],
                    ),
                  ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'UPJR Campus',
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              if (auth.showAdminTools) ...[
                                const SizedBox(width: 8),
                                const AdminBadge(),
                              ],
                            ],
                          ),
                          Text(
                            'Mapa interactivo',
                            style: TextStyle(
                              // En modo claro el cian se pierde: tono más oscuro.
                              color: isDark ? AppColors.accent.withValues(alpha: 0.9) : const Color(0xFF9A6412),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset('assets/logo.png', width: 48, height: 48),
                  ],
                ),
                const SizedBox(height: 12),
                GlassContainer(
                  radius: 18,
                  blur: 10,
                  child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'Buscar edificio, salón o categoría…',
                    hintStyle: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondaryLight),
                    prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  ),
                ),
                const SizedBox(height: 10),
                _CategoryChips(
                  wrap: wide,
                  children: _categories(mapProvider).map((cat) {
                      final selected = (_categoryFilter ?? 'Todos') == cat;
                      return Padding(
                        padding: EdgeInsets.only(right: wide ? 0 : 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _categoryFilter = cat == 'Todos' ? null : cat),
                          child: GlassContainer(
                            radius: 18,
                            blur: 0,
                            shadow: false,
                            tint: selected ? AppColors.primary : null,
                            tintStrength: selected ? 2.4 : 1,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                  color: isDark ? Colors.white : (selected ? AppColors.onAccent : AppColors.textPrimaryLight),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ),
                // Salones que coinciden con la búsqueda ("salón 7", "ud2 7").
                if (_searchQuery.isNotEmpty && searchRooms(_searchQuery).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GlassContainer(
                    radius: 18,
                    blur: 10,
                    tintStrength: wide ? 1 : 1.6,
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: RoomSearchResults(query: _searchQuery, max: wide ? 5 : 3),
                  ),
                ],
                // PC: lista de lugares bajo los filtros.
                if (wide) ...[
                  const SizedBox(height: 18),
                  Text(
                    'LUGARES',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(child: _buildPlacesList(mapProvider, visible, isDark)),
                ],
              ],
            ),
          ),
        ),

        if (auth.showAdminTools && mapProvider.selectedMapLocation == null)
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton.extended(
              heroTag: 'admin_hub',
              backgroundColor: AppColors.admin,
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              label: const Text('Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => context.push('/admin'),
            ),
          ),

        // Edificio abierto: nombre, botón de información y salir.
        if (_focusId != null && mapProvider.selectedMapLocation == null)
          Builder(builder: (context) {
            final b = mapProvider.mapPoints.where((l) => l.id == _focusId).firstOrNull;
            if (b == null) return const SizedBox.shrink();
            return Positioned(
              left: barLeft,
              right: !wide && auth.showAdminTools ? 140 : barRight,
              bottom: 100,
              child: GlassContainer(
                radius: 20,
                blur: 12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  if (kFloorPlans[b.id] case final floors?) ...[
                    Row(
                      children: [
                        for (var i = 0; i < floors.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(floors[i].label),
                              tooltip: floors[i].name,
                              selected: i == _floor,
                              selectedColor: AppColors.accent.withValues(alpha: 0.35),
                              onSelected: (_) => setState(() {
                                _floor = i;
                                _zone = null;
                              }),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _zone == null
                                ? '${floors[_floor].name} · toca una zona'
                                : '${_zone!.name}${_zone!.detail != null ? ' — ${_zone!.detail}' : ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: _zone == null
                                  ? (isDark ? Colors.white60 : Colors.black54)
                                  : (isDark ? Colors.white : AppColors.textPrimaryLight),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_zone?.guide case (final label, final route) when auth.canSeePrivate)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.push(route),
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: Text(label),
                          style: TextButton.styleFrom(foregroundColor: AppColors.highlight),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(b.icon, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(b.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      TextButton(
                        onPressed: () => mapProvider.selectMapLocation(b),
                        child: Text(roomsOf(b.id).isNotEmpty ? 'Ver salones' : 'Ver información'),
                      ),
                      IconButton(
                        tooltip: 'Salir del edificio',
                        icon: const Icon(Icons.close_rounded),
                        color: isDark ? Colors.white70 : Colors.black54,
                        onPressed: _resetZoom,
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ),
            );
          }),

        if (hoverCard != null) hoverCard,

        if (sidePanel)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 16,
            bottom: 16,
            width: panelW,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LocationDetailSheet(
                location: mapProvider.selectedMapLocation!,
                scrollController: _sidePanelScroll,
                onClose: () => mapProvider.selectMapLocation(null),
                navInset: 0,
              ),
            ),
          )
        else if (mapProvider.selectedMapLocation != null)
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.22,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.5, 0.92],
            builder: (context, scrollController) {
              return LocationDetailSheet(
                location: mapProvider.selectedMapLocation!,
                scrollController: scrollController,
                onClose: () => mapProvider.selectMapLocation(null),
              );
            },
          ),

        const MapOnboardingOverlay(),
      ],
    );
  }
}


class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;

  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 24, color: isDark ? Colors.white : AppColors.textPrimaryLight),
        ),
      ),
    );
  }
}


/// Vista previa breve de un edificio: foto, nombre, categoría y descripción.
class _PinPreviewCard extends StatelessWidget {
  final MapLocation location;

  const _PinPreviewCard({required this.location});

  @override
  Widget build(BuildContext context) {
    final photo = location.equipmentImages.isNotEmpty ? location.equipmentImages.first : null;

    return GlassContainer(
      radius: 20,
      blur: 12,
      tint: const Color(0xFF222B3A),
      tintStrength: 3.4,
      uniform: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null)
            SizedBox(
              height: 105,
              width: double.infinity,
              child: Image.asset(
                photo,
                fit: BoxFit.cover,
                cacheWidth: 500,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black26),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  location.category.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.highlight,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  location.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                if (location.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    location.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña y semitransparente: da contexto sin tapar el mapa.
class _SubtleLabel extends StatelessWidget {
  const _SubtleLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Filtros de categoría: fila deslizable (teléfono) o chips que se acomodan
/// en varias líneas (PC, barra lateral).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.wrap, required this.children});
  final bool wrap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (wrap) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final c in children) SizedBox(height: 34, child: IntrinsicWidth(child: c))],
      );
    }
    return SizedBox(
      height: 36,
      child: ListView(scrollDirection: Axis.horizontal, children: children),
    );
  }
}
