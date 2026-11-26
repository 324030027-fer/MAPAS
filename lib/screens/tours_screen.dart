import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../data/building_outlines.dart' show kShortNames;
import '../data/rooms.dart';
import '../data/tours/tours.dart';
import '../models/tour.dart';
import '../providers/map_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass.dart';
import '../widgets/responsive.dart';
import '../widgets/room_picker.dart';
import 'panorama_viewer.dart';

/// Pestaña Recorridos, ordenada por intención:
/// 1. Ir directo a un salón (lo más buscado).
/// 2. Recorridos completos por edificio.
/// 3. Laboratorios en 360°.
class ToursScreen extends StatefulWidget {
  const ToursScreen({super.key});

  @override
  State<ToursScreen> createState() => _ToursScreenState();
}

class _ToursScreenState extends State<ToursScreen> {
  late final List<String> _buildings = buildingsWithRooms();
  late String? _building = _buildings.isEmpty ? null : _buildings.first;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : AppColors.textPrimaryLight;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GlassScaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 900,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recorridos 360°', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: fg)),
                            const SizedBox(height: 4),
                            Text('Entra directo a un salón o recorre un edificio', style: TextStyle(color: muted)),
                          ],
                        ),
                      ),
                      Image.asset('assets/logo.png', width: 48, height: 48),
                    ],
                  ),
                ),
              ),

              // 1. Ir directo a un salón
              if (_building != null) ...[
                _SectionHeader('IR DIRECTO A UN SALÓN', top: 20),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassContainer(
                      radius: 24,
                      blur: 10,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_buildings.length > 1) ...[
                            SegmentedButton<String>(
                              segments: [
                                for (final b in _buildings) ButtonSegment(value: b, label: Text(kShortNames[b] ?? b)),
                              ],
                              selected: {_building!},
                              onSelectionChanged: (s) => setState(() => _building = s.first),
                              showSelectedIcon: false,
                            ),
                            const SizedBox(height: 14),
                          ] else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.apartment_rounded, color: isDark ? AppColors.accent : AppColors.accentOnLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Edificio ${kShortNames[_building] ?? _building}',
                                    style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          RoomPicker(buildingId: _building!),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              // 2. Recorridos completos
              _SectionHeader('RECORRIDOS COMPLETOS', top: 28),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final tour = kTours[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: _TourCard(
                        title: tour.title,
                        subtitle: tour.subtitle,
                        imageAsset: tour.coverAsset,
                        badge: tour.badge,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PanoramaViewer(tour: tour)),
                        ),
                      ),
                    );
                  },
                  childCount: kTours.length,
                ),
              ),

              // 3. Laboratorios
              _SectionHeader('LABORATORIOS EN 360°', top: 14),
              SliverToBoxAdapter(child: _Lab360List()),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.top = 20});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, top, 20, 10),
        child: Text(
          text,
          style: TextStyle(
            color: isDark ? AppColors.accent : AppColors.accentOnLight,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final String badge;
  final VoidCallback onTap;

  const _TourCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(image: ResizeImage(AssetImage(imageAsset), width: 1000), fit: BoxFit.cover),
          ),
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xE61B2230)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              badge,
                              style: const TextStyle(color: AppColors.onAccent, fontSize: 10, fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      backgroundColor: AppColors.accent,
                      radius: 24,
                      child: Icon(Icons.play_arrow_rounded, color: AppColors.onAccent, size: 30),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Lab360List extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final labs = <({String name, String asset})>[];

    for (final loc in mapProvider.mapPoints) {
      for (final career in loc.careers) {
        for (final lab in career.labs) {
          if (lab.asset360 != null && lab.asset360!.isNotEmpty) {
            labs.add((name: lab.name, asset: lab.asset360!));
          }
        }
      }
    }

    if (labs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: EmptyState(
          icon: Icons.vrpano_outlined,
          title: 'Sin tours de laboratorio',
          subtitle: 'Los administradores pueden vincular panoramas 360° desde el panel.',
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: labs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final lab = labs[i];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PanoramaViewer(
                    tour: Tour.single(title: lab.name, asset: lab.asset),
                  ),
                ),
              );
            },
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                image: DecorationImage(image: ResizeImage(AssetImage(lab.asset), width: 500), fit: BoxFit.cover),
              ),
              child: Container(
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                  ),
                ),
                child: Text(
                  lab.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
