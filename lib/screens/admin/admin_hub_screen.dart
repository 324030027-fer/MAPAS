import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';
import 'admin_dashboard.dart';
import 'map_pin_editor_screen.dart';
import 'schedule_admin_screen.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        appBar: AppBar(
          title: const Text('Panel de administración'),
          bottom: const TabBar(
            indicatorColor: AppColors.highlight,
            labelColor: AppColors.highlight,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'Puntos'),
              Tab(icon: Icon(Icons.map), text: 'Mapa'),
              Tab(icon: Icon(Icons.schedule), text: 'Horarios'),
              Tab(icon: Icon(Icons.visibility), text: 'Vista previa'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminDashboard(embedded: true),
            MapPinEditorScreen(embedded: true),
            ScheduleAdminScreen(embedded: true),
            _PreviewTab(),
          ],
        ),
      ),
    );
  }
}

class _PreviewTab extends StatelessWidget {
  const _PreviewTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android, size: 72, color: AppColors.accent.withValues(alpha: 0.8)),
            const SizedBox(height: 24),
            const Text(
              'Vista previa estudiante',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Activa la vista estudiante para ocultar botones de admin en el mapa y navegar como un invitado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryDark, height: 1.5),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () {
                auth.setPreviewAsStudent(true);
                context.go('/');
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Abrir app como estudiante'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => auth.setPreviewAsStudent(false),
              child: const Text('Desactivar vista estudiante'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Activa horarios en un edificio desde el panel de puntos.
Future<void> enableSchedulesForLocation(
  BuildContext context,
  String locationId,
  String locationTitle,
) async {
  final scheduleProvider = context.read<ScheduleProvider>();
  await scheduleProvider.ensureLocationExists(locationId);
  final existing = scheduleProvider.getSchedulesForLocation(locationId);
  if (existing.isNotEmpty) return;

  await scheduleProvider.addLab(locationId, 'Laboratorio — $locationTitle');
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Horarios activados para $locationTitle. Edítalos en la pestaña Horarios.'),
        action: SnackBarAction(
          label: 'Ir',
          onPressed: () {},
        ),
      ),
    );
  }
}
