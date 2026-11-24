import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/building_outlines.dart';
import '../../models/map_location.dart';
import '../../providers/map_provider.dart';
import '../../widgets/map_widgets.dart';
import '../../widgets/responsive.dart';

/// Alta de una ubicación nueva: se toca el mapa para elegir el punto y el
/// formulario completa solo el ID y las coordenadas. Se guarda en Firestore
/// (lo ven todos al momento).
class NewLocationScreen extends StatefulWidget {
  const NewLocationScreen({super.key});

  @override
  State<NewLocationScreen> createState() => _NewLocationScreenState();
}

class _NewLocationScreenState extends State<NewLocationScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _features = TextEditingController();
  final _newCategory = TextEditingController();
  final _transformer = TransformationController();

  Offset? _point; // coordenadas normalizadas 0..1
  String? _category;
  String _iconName = 'Lugar';
  static const _newCatValue = '__nueva__';

  @override
  void dispose() {
    for (final c in [_title, _desc, _features, _newCategory]) {
      c.dispose();
    }
    _transformer.dispose();
    super.dispose();
  }

  /// ID legible y único a partir del título: "Sala de juntas" → SALA_DE_JUNTAS.
  String _makeId(String title, Set<String> taken) {
    const from = 'ÁÉÍÓÚÜÑáéíóúüñ';
    const to = 'AEIOUUNaeiouun';
    var t = title.trim();
    for (var i = 0; i < from.length; i++) {
      t = t.replaceAll(from[i], to[i]);
    }
    var base = t.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'LUGAR';
    var id = base;
    for (var n = 2; taken.contains(id); n++) {
      id = '${base}_$n';
    }
    return id;
  }

  /// Edificio (silueta) que contiene el punto, si lo hay.
  String? _buildingAt(Offset p) {
    for (final e in kBuildingOutlines.entries) {
      if (outlineContains(e.value, p)) return e.key;
    }
    return null;
  }

  void _save(MapProvider provider) {
    if (_point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toca el mapa para elegir dónde va la ubicación')),
      );
      return;
    }
    if (!_form.currentState!.validate()) return;
    final category = _category == _newCatValue ? _newCategory.text.trim() : _category!;
    final taken = provider.mapPoints.map((l) => l.id).toSet();
    final loc = MapLocation(
      id: _makeId(_title.text, taken),
      title: _title.text.trim().toUpperCase(),
      description: _desc.text.trim(),
      category: category,
      x: double.parse(_point!.dx.toStringAsFixed(4)),
      y: double.parse(_point!.dy.toStringAsFixed(4)),
      assetImage360: '',
      icon: kLocationIcons[_iconName]!,
      features: _features.text.trim().isEmpty
          ? ''
          : _features.text.trim().split('\n').map((l) => l.startsWith('•') ? l : '• $l').join('\n'),
    );
    provider.addMapPoint(loc);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ubicación "${loc.title}" guardada (${loc.id})')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();
    final wide = Breakpoints.isWide(context);
    final categories = (provider.mapPoints.map((l) => l.category).where((c) => c.isNotEmpty).toSet().toList()..sort());

    final map = _buildMap(provider);
    final form = _buildForm(provider, categories);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Nueva ubicación'),
        backgroundColor: AppColors.darkBg,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _save(provider),
              icon: const Icon(Icons.check),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(children: [
              SizedBox(width: 380, child: form),
              const VerticalDivider(width: 1, color: Colors.white12),
              Expanded(child: map),
            ])
          : Column(children: [
              Expanded(flex: 5, child: map),
              const Divider(height: 1, color: Colors.white12),
              Expanded(flex: 4, child: form),
            ]),
    );
  }

  Widget _buildMap(MapProvider provider) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformer,
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth, h = c.maxHeight;
                return GestureDetector(
                  onTapUp: (d) => setState(() => _point = Offset(
                        (d.localPosition.dx / w).clamp(0.01, 0.99),
                        (d.localPosition.dy / h).clamp(0.01, 0.99),
                      )),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Image.asset('assets/mapa_base.jpg', fit: BoxFit.cover, width: w, height: h),
                      // Lugares existentes, tenues, como referencia.
                      for (final loc in provider.mapPoints)
                        Positioned(
                          left: loc.x * w - 7,
                          top: loc.y * h - 7,
                          child: IgnorePointer(
                            child: Tooltip(
                              message: loc.title,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black26),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_point != null)
                        Positioned(
                          left: _point!.dx * w - 20,
                          top: _point!.dy * h - 20,
                          width: 40,
                          height: 48,
                          child: GestureDetector(
                            // Arrastrar el pin para afinar la posición.
                            onPanUpdate: (d) => setState(() => _point = Offset(
                                  (_point!.dx + d.delta.dx / w).clamp(0.01, 0.99),
                                  (_point!.dy + d.delta.dy / h).clamp(0.01, 0.99),
                                )),
                            child: MapMarker(
                              location: MapLocation(
                                id: '_nuevo',
                                title: _title.text.isEmpty ? 'Nueva' : _title.text,
                                description: '',
                                category: '',
                                x: _point!.dx,
                                y: _point!.dy,
                                assetImage360: '',
                                icon: kLocationIcons[_iconName]!,
                              ),
                              isSelected: true,
                              onTap: () {},
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.darkSurface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
            child: Text(
              _point == null ? 'Toca el mapa donde va la ubicación' : 'Arrastra el pin para ajustarlo',
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(MapProvider provider, List<String> categories) {
    InputDecoration deco(String label, {String? hint}) => InputDecoration(labelText: label, hintText: hint, isDense: true);
    final building = _point == null ? null : _buildingAt(_point!);
    final buildingName = building == null ? null : provider.mapPoints.where((l) => l.id == building).firstOrNull?.title;

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Datos que se llenan solos.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Se llenan solos', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  _point == null
                      ? 'Posición: toca el mapa'
                      : 'Posición: X ${_point!.dx.toStringAsFixed(3)} · Y ${_point!.dy.toStringAsFixed(3)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                Text(
                  'ID: ${_title.text.trim().isEmpty ? '(a partir del título)' : _makeId(_title.text, provider.mapPoints.map((l) => l.id).toSet())}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                if (buildingName != null)
                  Text('Dentro de: $buildingName', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _title,
            decoration: deco('Nombre', hint: 'Ej. Sala de juntas'),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: deco('Categoría'),
            items: [
              for (final c in categories) DropdownMenuItem(value: c, child: Text(c)),
              const DropdownMenuItem(value: _newCatValue, child: Text('+ Nueva categoría…')),
            ],
            onChanged: (v) => setState(() => _category = v),
            validator: (v) => v == null ? 'Elige una categoría' : null,
          ),
          if (_category == _newCatValue) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _newCategory,
              decoration: deco('Nombre de la categoría nueva'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe la categoría' : null,
            ),
          ],
          const SizedBox(height: 16),
          const Text('Ícono', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in kLocationIcons.entries)
                Tooltip(
                  message: e.key,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _iconName = e.key),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _iconName == e.key ? AppColors.primary : AppColors.darkSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e.value, size: 20, color: _iconName == e.key ? AppColors.onAccent : Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _desc, decoration: deco('Descripción (opcional)'), maxLines: 2),
          const SizedBox(height: 12),
          TextFormField(
            controller: _features,
            decoration: deco('Características (opcional)', hint: 'Una por línea'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
