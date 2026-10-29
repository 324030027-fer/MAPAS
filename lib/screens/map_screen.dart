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

class _MapScreenState extends State<MapScreen> {
  final TransformationController _transformer = TransformationController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _categoryFilter;

  @override
  void dispose() {
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

    return Stack(
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
              transformationController: _transformer,
              minScale: 1.0,
              maxScale: 5.0,
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
                          ...visible.map((loc) {
                            return Positioned(
                              left: (loc.x * constraints.maxWidth) - 20,
                              top: (loc.y * constraints.maxHeight) - 20,
                              width: 40,
                              height: 48,
                              child: MapMarker(
                                location: loc,
                                isSelected: mapProvider.selectedMapLocation?.id == loc.id,
                                onTap: () => mapProvider.selectMapLocation(loc),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
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
