import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/map_location.dart';
import '../core/theme/app_colors.dart';
import '../providers/map_provider.dart';
import '../providers/schedule_provider.dart';
import '../screens/panorama_viewer.dart';
import 'glass.dart';
import 'lab_schedule_viewer.dart';

// --- MARCADOR ---
class MapMarker extends StatelessWidget {
  final MapLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  const MapMarker({super.key, required this.location, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const double size = 40.0;
    final Color mainColor = isSelected ? AppColors.highlight : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size, height: size,
              decoration: BoxDecoration(
                color: mainColor, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [BoxShadow(color: mainColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
              ),
              child: Icon(location.icon, color: Colors.white, size: 20),
            ),
            Positioned(
              top: size + 6,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: GlassTag(
                child: Text(location.title, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PANEL DETALLADO CON PESTAÑAS DINÁMICAS Y CARRUSEL DE FOTOS ---
class LocationDetailSheet extends StatelessWidget {
  final MapLocation location;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  const LocationDetailSheet({
    super.key,
    required this.location,
    this.scrollController,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final schedules = scheduleProvider.getSchedulesForLocation(location.id);
    final bool hasLaboratories = location.careers.isNotEmpty;
    final bool hasSchedules = schedules.isNotEmpty;

    List<String> tabTitles = ['DESCRIPCIÓN', 'FOTOS'];
    if (hasLaboratories) tabTitles.add('LABORATORIOS');
    if (hasSchedules) tabTitles.add('HORARIOS');

    return GlassContainer(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      blur: 28,
      tint: const Color(0xFF23233A),
      tintStrength: 3.4,
      uniform: true,
      child: DefaultTabController(
        length: tabTitles.length,
        child: Column(
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.highlight.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(location.icon, color: AppColors.highlight, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.highlight,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location.title,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 32),
                      tooltip: 'Cerrar',
                      onPressed: onClose,
                    ),
                ],
              ),
            ),
            TabBar(
              indicatorColor: const Color(0xFFFF8C00),
              labelColor: const Color(0xFFFF8C00),
              unselectedLabelColor: Colors.white70,
              tabs: tabTitles.map((title) => Tab(text: title)).toList(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // DESCRIPCIÓN MEJORADA
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.description, color: const Color(0xFFFF8C00), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                location.description,
                                style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (location.features.isNotEmpty && location.features != "• Acceso Controlado") ...[
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2C),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: const Color(0xFFFF8C00), size: 18),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "CARACTERÍSTICAS DESTACADAS",
                                        style: TextStyle(
                                          color: Color(0xFFFF8C00),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._parseFeaturesToList(location.features),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (location.id == 'LT_MAP') ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final provider = context.read<MapProvider>();
                                final start = provider.getTourLocationById('E1');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PanoramaViewer(initialLocation: start)),
                                );
                              },
                              icon: const Icon(Icons.vrpano),
                              label: const Text('INICIAR RECORRIDO 360° DEL LT'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                side: const BorderSide(color: AppColors.accent),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _LocationPhotoCarousel(images: location.equipmentImages),
                  // LABORATORIOS (si existen)
                  if (hasLaboratories)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: location.careers.map((career) => _buildCareerSection(context, career)).toList()),
                    ),
                  // HORARIOS (si existen)
                  if (hasSchedules)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: LabScheduleViewer(schedules: schedules),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Convierte texto de características en lista de widgets con viñetas
  List<Widget> _parseFeaturesToList(String features) {
    final lines = features.split('\n');
    return lines.where((line) => line.trim().isNotEmpty).map((line) {
      String cleanLine = line.trim().replaceFirst(RegExp(r'^[•\-*]\s*'), '');
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFFF8C00), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(cleanLine, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCareerSection(BuildContext context, CareerInfo career) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(career.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.school, color: Color(0xFFFF8C00)),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: career.labs.map((lab) => _buildLabItem(context, lab)).toList(),
        ),
      ),
    );
  }

  Widget _buildLabItem(BuildContext context, LabInfo lab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF2D2D44), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(lab.imageThumbnail, width: 60, height: 60, cacheWidth: 180, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lab.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Encargado: ${lab.inCharge}", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                    Text(lab.contact, style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(lab.description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          if (lab.asset360 != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final tempLoc = MapLocation(
                    id: 'TEMP_LAB', title: lab.name, description: '', category: 'Laboratorio',
                    x: 0, y: 0, assetImage360: lab.asset360!,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PanoramaViewer(initialLocation: tempLoc)));
                },
                icon: const Icon(Icons.threesixty, size: 18),
                label: const Text("VER LABORATORIO EN VISTA 360"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF8C00),
                  side: const BorderSide(color: Color(0xFFFF8C00)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationPhotoCarousel extends StatefulWidget {
  final List<String> images;

  const _LocationPhotoCarousel({required this.images});

  @override
  State<_LocationPhotoCarousel> createState() => _LocationPhotoCarouselState();
}

class _LocationPhotoCarouselState extends State<_LocationPhotoCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const Center(
        child: Text('No hay fotos disponibles', style: TextStyle(color: Colors.white54)),
      );
    }

    final imagePath = widget.images[_currentIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 250,
          child: GestureDetector(
            onTap: () => _showFullImageDialog(context, imagePath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 250,
                cacheWidth: 900,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white54, size: 80),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (i) {
            return Container(
              width: i == _currentIndex ? 10 : 7,
              height: i == _currentIndex ? 10 : 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == _currentIndex ? AppColors.highlight : Colors.white38,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00)),
              onPressed: _currentIndex > 0
                  ? () => setState(() => _currentIndex--)
                  : null,
            ),
            Text(
              '${_currentIndex + 1} / ${widget.images.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFFFF8C00)),
              onPressed: _currentIndex < widget.images.length - 1
                  ? () => setState(() => _currentIndex++)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

void _showFullImageDialog(BuildContext context, String imagePath) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(imagePath, fit: BoxFit.contain, width: double.infinity, cacheWidth: 1600),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}