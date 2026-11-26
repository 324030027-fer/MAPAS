import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../widgets/glass.dart';
import '../widgets/responsive.dart';

/// Integrantes del equipo NullCore. PENDIENTE: llenar nombre, rol y foto
/// (assets/team/...) de las 5 personas.
const List<({String name, String role, String photo})> kTeam = [
  (name: 'Integrante 1', role: 'Por definir', photo: ''),
  (name: 'Integrante 2', role: 'Por definir', photo: ''),
  (name: 'Integrante 3', role: 'Por definir', photo: ''),
  (name: 'Integrante 4', role: 'Por definir', photo: ''),
  (name: 'Integrante 5', role: 'Por definir', photo: ''),
];

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = dark ? Colors.white : AppColors.textPrimaryLight;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
        backgroundColor: Colors.transparent,
        foregroundColor: fg,
        elevation: 0,
      ),
      body: ListView(
        padding: centeredListPadding(context, top: 8, bottom: 40),
        children: [
          Center(
            child: Container(
              width: 104,
              height: 104,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
              ),
              child: Image.asset('assets/logoapp.png'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NULLCORE MAPS',
            textAlign: TextAlign.center,
            style: TextStyle(color: fg, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text('Versión 1.2 · Campus UPJR', textAlign: TextAlign.center, style: TextStyle(color: muted)),
          const SizedBox(height: 22),
          GlassContainer(
            radius: 22,
            blur: 0,
            padding: const EdgeInsets.all(18),
            child: Text(
              'Mapa interactivo de la Universidad Politécnica de Juventino Rosas para '
              'estudiantes, aspirantes y visitantes: ubica edificios y salones, '
              'entra a ellos en 360°, consulta el calendario escolar y contacta a tus profesores.',
              style: TextStyle(color: fg, height: 1.5, fontSize: 14),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'EQUIPO NULLCORE',
              style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3),
            ),
          ),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 560 ? 5 : 3;
              final w = (c.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final m in kTeam)
                    SizedBox(
                      width: w,
                      child: GlassContainer(
                        radius: 18,
                        blur: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.accent.withValues(alpha: 0.18),
                              foregroundImage: m.photo.isEmpty ? null : AssetImage(m.photo),
                              child: Icon(Icons.person_rounded, color: dark ? AppColors.accent : AppColors.accentOnLight),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              m.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              m.role,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: muted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          Text(
            'Hecho con Flutter y Firebase · Universidad Politécnica de Juventino Rosas',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
