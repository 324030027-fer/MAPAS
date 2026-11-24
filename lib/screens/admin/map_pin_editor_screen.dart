import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/map_location.dart';
import '../../providers/map_provider.dart';
import '../../widgets/grid_painter.dart';
import '../../widgets/map_widgets.dart';
import '../../widgets/glass.dart';

class MapPinEditorScreen extends StatefulWidget {
  final bool embedded;

  const MapPinEditorScreen({super.key, this.embedded = false});

  @override
  State<MapPinEditorScreen> createState() => _MapPinEditorScreenState();
}

class _MapPinEditorScreenState extends State<MapPinEditorScreen> {
  final TransformationController _transformer = TransformationController();
  MapLocation? _selected;
  /// Posiciones movidas que aún no se guardan (id → x,y). Nada se sube a
  /// Firestore hasta presionar "Guardar".
  final Map<String, Offset> _pending = {};
  double _mapWidth = 1;
  double _mapHeight = 1;

  @override
  void dispose() {
    _transformer.dispose();
    super.dispose();
  }

  /// Lugar con su posición pendiente (si se movió) aplicada.
  MapLocation _withPending(MapLocation loc) {
    final p = _pending[loc.id];
    return p == null ? loc : loc.copyWith(x: p.dx, y: p.dy);
  }

  void _updatePosition(MapLocation loc, Offset delta) {
    final cur = _withPending(loc);
    final newX = (cur.x + delta.dx / _mapWidth).clamp(0.02, 0.98);
    final newY = (cur.y + delta.dy / _mapHeight).clamp(0.02, 0.98);
    setState(() => _pending[loc.id] = Offset(newX, newY));
  }

  void _placeAtTap(Offset local, MapProvider provider) {
    if (_selected == null) return;
    final x = (local.dx / _mapWidth).clamp(0.02, 0.98);
    final y = (local.dy / _mapHeight).clamp(0.02, 0.98);
    setState(() => _pending[_selected!.id] = Offset(x, y));
  }

  void _save(MapProvider provider) {
    final n = _pending.length;
    for (final loc in provider.mapPoints) {
      if (_pending.containsKey(loc.id)) provider.updateMapPoint(_withPending(loc));
    }
    setState(_pending.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(n == 1 ? '1 posición guardada' : '$n posiciones guardadas')),
    );
  }

  void _discard() => setState(_pending.clear);

  /// Barra de cambios sin guardar.
  Widget _saveBar(MapProvider provider) {
    final n = _pending.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      color: n == 0 ? AppColors.darkSurface : AppColors.primary.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            n == 0 ? 'Sin cambios' : (n == 1 ? '1 cambio sin guardar' : '$n cambios sin guardar'),
            style: TextStyle(color: n == 0 ? Colors.white54 : AppColors.highlight, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: n == 0 ? null : _discard, child: const Text('Descartar')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: n == 0 ? null : () => _save(provider),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
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
                  'Selecciona un punto y arrastra el pin, o toca el mapa para colocarlo. '
                  'Los cambios se suben hasta que presiones Guardar.',
                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, height: 1.4),
                ),
              ),
              _saveBar(provider),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.mapPoints.length,
                  itemBuilder: (context, index) {
                    final loc = _withPending(provider.mapPoints[index]);
                    final moved = _pending.containsKey(loc.id);
                    final isSelected = _selected?.id == loc.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
                      leading: Icon(loc.icon, color: isSelected ? AppColors.highlight : AppColors.accent),
                      title: Text(loc.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text(
                        'X:${loc.x.toStringAsFixed(2)} Y:${loc.y.toStringAsFixed(2)}${moved ? '  · sin guardar' : ''}',
                        style: TextStyle(color: moved ? AppColors.highlight : Colors.white54, fontSize: 11),
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
                          ...provider.mapPoints.map(_withPending).map((loc) {
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
      return Material(color: AppColors.darkBg, child: body);
    }

    return GlassScaffold(
      forceDark: true,
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(title: const Text('Editor visual de pins')),
      body: body,
    );
  }
}
