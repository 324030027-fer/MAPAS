import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/map_location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/schedule_provider.dart';
import 'admin_hub_screen.dart';
import 'location_editor.dart';
import '../../widgets/glass.dart';

class AdminDashboard extends StatelessWidget {
  final bool embedded;

  const AdminDashboard({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    if (!embedded) {
      final auth = Provider.of<AuthProvider>(context);
      if (!auth.isAdmin) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
    }

    final provider = Provider.of<MapProvider>(context);

    final list = provider.mapPoints.isEmpty
        ? const Center(
            child: Text('No hay puntos en el mapa.', style: TextStyle(color: Colors.white)),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.mapPoints.length,
            itemBuilder: (context, index) {
              final loc = provider.mapPoints[index];
              final hasSchedules = context.watch<ScheduleProvider>().hasSchedulesForLocation(loc.id);
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.highlight.withValues(alpha: 0.2),
                    child: Icon(loc.icon, color: AppColors.highlight),
                  ),
                  title: Text(loc.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text(
                    '${loc.category} · X:${loc.x.toStringAsFixed(2)} Y:${loc.y.toStringAsFixed(2)}'
                    '${hasSchedules ? ' · Con horarios' : ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!hasSchedules)
                        IconButton(
                          tooltip: 'Activar horarios',
                          icon: const Icon(Icons.schedule, color: AppColors.accent),
                          onPressed: () => enableSchedulesForLocation(context, loc.id, loc.title),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LocationEditor(location: loc)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => _confirmDelete(context, provider, loc),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

    if (embedded) {
      return Column(
        children: [
          Expanded(child: list),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showAddLocationDialog(context, provider),
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Nueva ubicación'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.highlight),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GlassScaffold(
      forceDark: true,
      appBar: AppBar(title: const Text('Gestión de puntos')),
      backgroundColor: AppColors.darkBg,
      body: list,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLocationDialog(context, provider),
        label: const Text('Nueva ubicación'),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: AppColors.highlight,
      ),
    );
  }

  void _confirmDelete(BuildContext context, MapProvider provider, MapLocation loc) {
    final scheduleCount = context.read<ScheduleProvider>().getSchedulesForLocation(loc.id).length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('¿Eliminar ubicación?', style: TextStyle(color: Colors.white)),
        content: Text(
          scheduleCount > 0
              ? 'Se borrará "${loc.title}" y sus horarios asociados ($scheduleCount lab(s)).'
              : 'Se borrará permanentemente: ${loc.title}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              provider.removeMapPoint(loc.id);
              Navigator.pop(context);
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context, MapProvider provider) {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final catController = TextEditingController();
    final xController = TextEditingController(text: '0.5');
    final yController = TextEditingController(text: '0.5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Nueva ubicación', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(idController, 'ID (único)'),
              _field(titleController, 'Título'),
              _field(descController, 'Descripción'),
              _field(catController, 'Categoría'),
              _field(xController, 'Coordenada X (0-1)', number: true),
              _field(yController, 'Coordenada Y (0-1)', number: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final id = idController.text.trim();
              if (id.isEmpty) return;
              provider.addMapPoint(MapLocation(
                id: id,
                title: titleController.text.trim(),
                description: descController.text.trim(),
                category: catController.text.trim(),
                x: double.tryParse(xController.text.trim()) ?? 0.5,
                y: double.tryParse(yController.text.trim()) ?? 0.5,
                assetImage360: '',
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}
