import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/admin_badge.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            _Header(auth: auth, isDark: isDark),
            const SizedBox(height: 20),
            _SectionTitle('Campus', isDark: isDark),
            _Tile(
              icon: Icons.search,
              title: 'Buscar horarios',
              subtitle: 'Materia, profesor, grupo o día',
              onTap: () => context.push('/search-schedules'),
              isDark: isDark,
            ),
            _Tile(
              icon: Icons.contacts,
              title: 'Contactos',
              subtitle: 'Directorio de profesores',
              onTap: () => context.push('/contacts'),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _SectionTitle('Preferencias', isDark: isDark),
            SwitchListTile(
              secondary: Icon(
                theme.isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.accent,
              ),
              title: Text(
                'Modo oscuro',
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight),
              ),
              subtitle: Text(
                theme.isDark ? 'Activado' : 'Modo claro',
                style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              value: theme.isDark,
              activeThumbColor: AppColors.primary,
              onChanged: (_) => theme.toggle(),
            ),
            if (auth.isAdmin) ...[
              const SizedBox(height: 16),
              _SectionTitle('Administración', isDark: isDark),
              _Tile(
                icon: Icons.admin_panel_settings,
                title: 'Panel de administración',
                subtitle: 'Mapa, horarios y vista previa',
                onTap: () => context.push('/admin'),
                isDark: isDark,
                accent: AppColors.admin,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility, color: AppColors.admin),
                title: Text(
                  'Vista estudiante',
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight),
                ),
                subtitle: const Text('Oculta herramientas admin en el mapa'),
                value: auth.previewAsStudent,
                activeThumbColor: AppColors.admin,
                onChanged: auth.setPreviewAsStudent,
              ),
            ],
            const SizedBox(height: 16),
            _SectionTitle('Ayuda', isDark: isDark),
            _Tile(
              icon: Icons.tour,
              title: 'Ver tutorial del mapa',
              onTap: () async {
                await context.read<OnboardingProvider>().reset();
              },
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Cerrar sesión', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'NULLCORE MAPS · UPJR Campus v1.1',
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AuthProvider auth;
  final bool isDark;

  const _Header({required this.auth, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Icon(
              auth.isAdmin ? Icons.shield : Icons.person,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.userName,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.roleLabel,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (auth.isAdmin && !auth.previewAsStudent) const AdminBadge(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SectionTitle(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final Color? accent;

  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.isDark,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.accent;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: ListTile(
        minVerticalPadding: 12,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white38 : AppColors.textSecondaryLight),
        onTap: onTap,
      ),
    );
  }
}
