import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/map_location.dart';
import '../../providers/map_provider.dart';
import '../../widgets/grid_painter.dart';
import '../../widgets/map_widgets.dart';

class MapPinEditorScreen extends StatefulWidget {
  final bool embedded;

  const MapPinEditorScreen({super.key, this.embedded = false});

  @override
  State<MapPinEditorScreen> createState() => _MapPinEditorScreenState();
}

class _MapPinEditorScreenState extends State<MapPinEditorScreen> {
  final TransformationController _transformer = TransformationController();
  MapLocation? _selected;
  double _mapWidth = 1;
  double _mapHeight = 1;

  @override
  void dispose() {
    _transformer.dispose();
    super.dispose();
  }

  void _updatePosition(MapLocation loc, Offset delta) {
    final provider = context.read<MapProvider>();
    final newX = (loc.x + delta.dx / _mapWidth).clamp(0.02, 0.98);
    final newY = (loc.y + delta.dy / _mapHeight).clamp(0.02, 0.98);
    provider.updateMapPoint(loc.copyWith(x: newX, y: newY));
    setState(() => _selected = loc.copyWith(x: newX, y: newY));
  }

  void _placeAtTap(Offset local, MapProvider provider) {
    if (_selected == null) return;
    final x = (local.dx / _mapWidth).clamp(0.02, 0.98);
    final y = (local.dy / _mapHeight).clamp(0.02, 0.98);
    final updated = _selected!.copyWith(x: x, y: y);
    provider.updateMapPoint(updated);
    setState(() => _selected = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Posición actualizada'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();

    final body = Row(
      children: [
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.darkSurface,
                child: const Text(
                  'Selecciona un punto y arrastra el pin, o toca el mapa para colocarlo.',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, height: 1.4),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.mapPoints.length,
                  itemBuilder: (context, index) {
                    final loc = provider.mapPoints[index];
                    final isSelected = _selected?.id == loc.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
                      leading: Icon(loc.icon, color: isSelected ? AppColors.highlight : AppColors.accent),
                      title: Text(loc.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text(
                        'X:${loc.x.toStringAsFixed(2)} Y:${loc.y.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      onTap: () => setState(() => _selected = loc),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: Colors.white12),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformer,
            minScale: 0.5,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(200),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _mapWidth = constraints.maxWidth;
                    _mapHeight = constraints.maxHeight;
                    return GestureDetector(
                      onTapUp: (d) => _placeAtTap(d.localPosition, provider),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Image.asset('assets/mapa_base.jpg', fit: BoxFit.cover, width: _mapWidth, height: _mapHeight),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(
                                color: AppColors.highlight.withValues(alpha: 0.35),
                                divisions: 10,
                              ),
                            ),
                          ),
                          ...provider.mapPoints.map((loc) {
                            final isSelected = _selected?.id == loc.id;
                            return Positioned(
                              left: (loc.x * _mapWidth) - 22,
                              top: (loc.y * _mapHeight) - 22,
                              child: GestureDetector(
                                onPanUpdate: isSelected
                                    ? (d) => _updatePosition(loc, d.delta)
                                    : null,
                                child: MapMarker(
                                  location: loc,
                                  isSelected: isSelected,
                                  onTap: () => setState(() => _selected = loc),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: AppColors.darkBg, child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Editor visual de pins')),
      body: body,
    );
  }
}
