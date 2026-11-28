import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/map_location.dart';
import '../../providers/auth_provider.dart';
import '../../providers/map_provider.dart';
import 'location_editor.dart';
import 'new_location_screen.dart';
import '../../widgets/glass.dart';
import '../../widgets/responsive.dart';

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
            padding: centeredListPadding(context, horizontal: 16, bottom: 16),
            itemCount: provider.mapPoints.length,
            itemBuilder: (context, index) {
              final loc = provider.mapPoints[index];
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
                    '${loc.category} · X:${loc.x.toStringAsFixed(2)} Y:${loc.y.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                  onPressed: () => _openNewLocation(context),
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
        onPressed: () => _openNewLocation(context),
        label: const Text('Nueva ubicación'),
        icon: const Icon(Icons.add_location_alt),
        backgroundColor: AppColors.highlight,
        foregroundColor: AppColors.onAccent,
      ),
    );
  }

  void _confirmDelete(BuildContext context, MapProvider provider, MapLocation loc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('¿Eliminar ubicación?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Se borrará permanentemente: ${loc.title}',
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

  void _openNewLocation(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewLocationScreen()));
  }
}
