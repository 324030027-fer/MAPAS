import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/admin_badge.dart';
import '../widgets/glass.dart';
import '../widgets/responsive.dart';

/// Enlaces oficiales.
const kSitoUrl = 'http://sito.upjr.edu.mx/';
const kUpjrUrl = 'https://upjr.edu.mx/principal.php';

Future<void> openExternal(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo abrir $url'), behavior: SnackBarBehavior.floating),
    );
  }
}

/// Pestaña "Más", de lo más usado a lo menos:
/// perfil → servicios UPJR → apariencia y ayuda → administración → sesión.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      body: SafeArea(
        child: ListView(
          padding: centeredListPadding(context, top: 16, bottom: 110),
          children: [
            _Header(auth: auth, isDark: isDark),
            const SizedBox(height: 24),

            // ---------- Servicios ----------
            _SectionTitle('Servicios UPJR', isDark: isDark),
            _FeatureCard(
              icon: Icons.description_rounded,
              title: 'Solicitar constancia',
              subtitle: 'Guía paso a paso: requisitos, pago y envío por correo',
              locked: !auth.canSeePrivate,
              onTap: () {
                if (auth.canSeePrivate) {
                  context.push('/constancias');
                } else {
                  _askLogin(context, auth);
                }
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final sito = _LinkCard(
                  icon: Icons.dashboard_customize_rounded,
                  tag: 'SITO',
                  title: 'Sistema de Información Táctico Operativo',
                  host: 'sito.upjr.edu.mx',
                  color: const Color(0xFF3B8EEA),
                  onTap: () => openExternal(context, kSitoUrl),
                );
                final upjr = _LinkCard(
                  icon: Icons.account_balance_rounded,
                  tag: 'UPJR',
                  title: 'Universidad Politécnica de Juventino Rosas',
                  host: 'upjr.edu.mx',
                  color: const Color(0xFF2FA36B),
                  onTap: () => openExternal(context, kUpjrUrl),
                );
                // Teléfonos muy angostos: una debajo de otra.
                if (c.maxWidth < 300) {
                  return Column(children: [sito, const SizedBox(height: 12), upjr]);
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: sito),
                      const SizedBox(width: 12),
                      Expanded(child: upjr),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ---------- Preferencias ----------
            _SectionTitle('Preferencias', isDark: isDark),
            const _ThemeCard(),
            _Tile(
              icon: Icons.tour_rounded,
              title: 'Ver tutorial del mapa',
              onTap: () => context.read<OnboardingProvider>().reset(),
              isDark: isDark,
            ),

            if (auth.isAdmin) ...[
              const SizedBox(height: 20),
              _SectionTitle('Administración', isDark: isDark),
              _Tile(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Panel de administración',
                subtitle: 'Mapa, puntos y vista previa',
                onTap: () => context.push('/admin'),
                isDark: isDark,
                accent: AppColors.admin,
              ),
              GlassCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  secondary: const Icon(Icons.visibility_rounded, color: AppColors.admin),
                  title: Text(
                    'Vista estudiante',
                    style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLight),
                  ),
                  subtitle: Text(
                    'Oculta herramientas admin en el mapa',
                    style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                  value: auth.previewAsStudent,
                  activeThumbColor: AppColors.admin,
                  onChanged: auth.setPreviewAsStudent,
                ),
              ),
            ],

            const SizedBox(height: 20),
            _SectionTitle('Información', isDark: isDark),
            _Tile(
              icon: Icons.info_outline_rounded,
              title: 'Acerca de',
              subtitle: 'NULLCORE MAPS y el equipo',
              onTap: () => context.push('/about'),
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, auth),
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: const Text('Cerrar sesión', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'NULLCORE MAPS · UPJR Campus v1.2',
                style: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondaryLight, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: Text(auth.role == UserRole.guest
            ? 'Volverás a la pantalla de inicio.'
            : 'Tendrás que entrar de nuevo con tu cuenta @upjr.edu.mx.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await auth.logout();
    if (context.mounted) context.go('/login');
  }

  static Future<void> _askLogin(BuildContext context, AuthProvider auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_outline_rounded),
        title: const Text('Solo comunidad UPJR'),
        content: const Text('La guía de constancias es para alumnos y personal. Inicia sesión con tu correo @upjr.edu.mx.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ahora no')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await auth.logout();
    if (context.mounted) context.go('/login');
  }
}

class _Header extends StatelessWidget {
  final AuthProvider auth;
  final bool isDark;

  const _Header({required this.auth, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final photo = auth.photoUrl;
    return GlassContainer(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            foregroundImage: photo == null || photo.isEmpty ? null : NetworkImage(photo),
            onForegroundImageError: photo == null || photo.isEmpty ? null : (_, __) {},
            child: Icon(auth.isAdmin ? Icons.shield_rounded : Icons.person_rounded, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.email ?? auth.roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
                if (auth.email != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      auth.roleLabel,
                      style: TextStyle(
                        color: isDark ? AppColors.accent : AppColors.accentOnLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

/// Tarjeta destacada (acción principal de la sección).
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle${locked ? '. Requiere cuenta UPJR' : ''}',
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0BC66), Color(0xFFE8A33D), Color(0xFFC9822A)],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Ícono grande de fondo, decorativo.
                Positioned(
                  right: -18,
                  bottom: -22,
                  child: Icon(icon, size: 130, color: Colors.white.withValues(alpha: 0.16)),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: AppColors.onAccent, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(color: AppColors.onAccent, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(color: AppColors.onAccent.withValues(alpha: 0.8), fontSize: 13, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        locked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                        color: AppColors.onAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enlace a un sitio externo: etiqueta grande, nombre y dominio.
class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.host,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String tag;
  final String title;
  final String host;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      link: true,
      label: '$tag, $title. Abre $host',
      child: GlassContainer(
        radius: 22,
        blur: 0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, color: color),
                      ),
                      const Spacer(),
                      Icon(Icons.open_in_new_rounded, size: 18, color: dark ? Colors.white38 : Colors.black38),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tag,
                    style: TextStyle(
                      color: dark ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    host,
                    style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Apariencia: claro / oscuro con un control segmentado.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.accent),
                ),
                const SizedBox(width: 14),
                Text(
                  'Apariencia',
                  style: TextStyle(color: dark ? Colors.white : AppColors.textPrimaryLight, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18), label: Text('Modo claro')),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18), label: Text('Modo oscuro')),
              ],
              selected: {theme.mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => theme.setMode(s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.accent,
                selectedForegroundColor: AppColors.onAccent,
                foregroundColor: dark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
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
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
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
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : AppColors.textSecondaryLight),
        onTap: onTap,
      ),
    );
  }
}
