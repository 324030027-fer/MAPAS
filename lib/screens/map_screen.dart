import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/schedule_utils.dart';
import '../models/map_location.dart';
import '../providers/auth_provider.dart';
import '../providers/map_provider.dart';
import '../providers/schedule_provider.dart';
import '../widgets/admin_badge.dart';
import '../widgets/glass.dart';
import '../widgets/grid_painter.dart';
import '../widgets/map_onboarding_overlay.dart';
import '../widgets/map_widgets.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
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
  String _searchQuery = '';
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
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

  void _resetZoom() => _animateTo(Matrix4.identity());

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
    _zoomAnim.dispose();
    _searchController.dispose();
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
    final scheduleProvider = context.watch<ScheduleProvider>();
    final visible = _visiblePoints(mapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    final nowInLt = entriesHappeningNow(scheduleProvider.getSchedulesForLocation('LT_MAP'));

    final hoverCard = _buildHoverCard(mapProvider, context);

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
        Positioned.fill(
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
                          // Pines de tamaño constante en pantalla: al acercar el
                          // mapa se separan en lugar de crecer junto con él.
                          Positioned.fill(
                            child: ValueListenableBuilder<Matrix4>(
                              valueListenable: _transformer,
                              builder: (context, matrix, _) {
                                final scale = matrix.getMaxScaleOnAxis().clamp(1.0, _maxZoom);
                                final selectedId = mapProvider.selectedMapLocation?.id;
                                // El seleccionado va al final para quedar encima.
                                final ordered = [
                                  ...visible.where((l) => l.id != selectedId),
                                  ...visible.where((l) => l.id == selectedId),
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
                                                mapProvider.selectMapLocation(loc);
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
          right: 12,
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
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
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
                              color: AppColors.accent.withValues(alpha: 0.9),
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
                    hintText: 'Buscar edificio o categoría…',
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
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories(mapProvider).map((cat) {
                      final selected = (_categoryFilter ?? 'Todos') == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
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
                                  color: selected || isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Clases ahora en LT
        if (nowInLt.isNotEmpty && mapProvider.selectedMapLocation == null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: GlassContainer(
              radius: 20,
              blur: 12,
              child: InkWell(
                onTap: () {
                  final lt = mapProvider.mapPoints.firstWhere((l) => l.id == 'LT_MAP');
                  mapProvider.selectMapLocation(lt);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.highlight.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule, color: AppColors.highlight, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'En curso en LT',
                              style: TextStyle(color: AppColors.highlight, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              nowInLt.first.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: isDark ? Colors.white54 : Colors.black45),
                    ],
                  ),
                ),
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

        if (hoverCard != null) hoverCard,

        if (mapProvider.selectedMapLocation != null)
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
      tint: const Color(0xFF23233A),
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
