import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/academic_calendar_view.dart';
import '../widgets/glass.dart';
import '../widgets/responsive.dart';
import 'contacts_screen.dart';

/// Pestaña "Escolar": calendario del año escolar y, debajo, el directorio de
/// profesores. En PC se muestran lado a lado.
class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  final _calendarKey = GlobalKey();
  final _contactsKey = GlobalKey();

  void _jump(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : AppColors.textPrimaryLight;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final side = Breakpoints.isDesktop(context);

    final calendar = Column(
      key: _calendarKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _SectionTitle(icon: Icons.calendar_month_rounded, title: 'Calendario escolar 2026'),
        SizedBox(height: 12),
        AcademicCalendarView(),
      ],
    );

    final contacts = Column(
      key: _contactsKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _SectionTitle(icon: Icons.contacts_rounded, title: 'Contactos de profesores'),
        SizedBox(height: 12),
        _ContactsOrLock(),
      ],
    );

    return GlassScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: centeredListPadding(context, maxWidth: side ? ContentWidth.wide : ContentWidth.page, top: 16, bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Escolar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: fg)),
                        const SizedBox(height: 4),
                        Text('Fechas importantes y contacto con profesores', style: TextStyle(color: muted)),
                      ],
                    ),
                  ),
                  Image.asset('assets/logo.png', width: 48, height: 48),
                ],
              ),
              if (!side) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    _JumpChip(icon: Icons.calendar_month_rounded, label: 'Calendario', onTap: () => _jump(_calendarKey)),
                    const SizedBox(width: 8),
                    _JumpChip(icon: Icons.contacts_rounded, label: 'Contactos', onTap: () => _jump(_contactsKey)),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              if (side)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: calendar),
                    const SizedBox(width: 28),
                    Expanded(flex: 2, child: contacts),
                  ],
                )
              else ...[
                calendar,
                const SizedBox(height: 32),
                contacts,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: dark ? AppColors.accent : AppColors.accentOnLight, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _JumpChip extends StatelessWidget {
  const _JumpChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 17, color: dark ? AppColors.accent : AppColors.accentOnLight),
      label: Text(label),
      labelStyle: TextStyle(
        color: dark ? Colors.white : AppColors.textPrimaryLight,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      backgroundColor: dark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.8),
      side: BorderSide(color: dark ? Colors.white12 : Colors.black12),
      shape: const StadiumBorder(),
    );
  }
}

/// El directorio es solo para la comunidad UPJR; a los invitados se les
/// explica cómo verlo.
class _ContactsOrLock extends StatelessWidget {
  const _ContactsOrLock();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.canSeePrivate) return const ContactsSection();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return GlassContainer(
      radius: 20,
      blur: 0,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.lock_outline_rounded, size: 34, color: dark ? AppColors.accent : AppColors.accentOnLight),
          const SizedBox(height: 10),
          Text(
            'Directorio para la comunidad UPJR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inicia sesión con tu correo @upjr.edu.mx para ver los correos de los profesores.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.login_rounded),
            label: const Text('Iniciar sesión UPJR'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.onAccent),
          ),
        ],
      ),
    );
  }
}
