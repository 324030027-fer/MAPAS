import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/schedule_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/schedule_utils.dart';
import '../models/lab_schedule.dart';
import '../models/map_location.dart';
import 'glass.dart';

// Tinte oscuro común de las ventanas de laboratorio (texto blanco encima).
const Color _kLabTint = Color(0xFF23233A);

/// Tamaño del hotspot que aloja a [LabHotspotCard] dentro del panorama.
const double kLabHotspotWidth = 240;
const double kLabHotspotHeight = 168;

/// Altura (grados sobre el horizonte) de la tarjeta del laboratorio en el
/// pasillo: casi a la altura de las flechas. No se encima con ellas porque la
/// tarjeta queda unos 20° a un lado de la flecha vecina.
const double kLabHotspotPitch = 4;

/// Ventana flotante pequeña que aparece en el recorrido en lugar de la flecha
/// de un laboratorio: foto de referencia, nombre, resumen y flecha para entrar.
///
/// Va dentro de un hotspot (con transformaciones 3D), por eso usa cristal sin
/// desenfoque del fondo (blur 0): tinte translúcido, borde y brillo.
class LabHotspotCard extends StatelessWidget {
  final LabInfo lab;
  final VoidCallback onEnter;

  const LabHotspotCard({super.key, required this.lab, required this.onEnter});

  @override
  Widget build(BuildContext context) {
    return Align(
      child: GestureDetector(
        onTap: onEnter,
        child: SizedBox(
          width: 230,
          child: GlassContainer(
            radius: 22,
            blur: 0,
            tint: _kLabTint,
            tintStrength: 3.6,
            uniform: true,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: Image.asset(
                          lab.imageThumbnail,
                          fit: BoxFit.cover,
                          cacheWidth: 200,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Colors.black26,
                            child: Icon(Icons.science, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'LABORATORIO',
                            style: TextStyle(
                              color: AppColors.highlight,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lab.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  lab.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'Entrar',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.95),
                            AppColors.primary.withValues(alpha: 0.9),
                          ],
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 12),
                        ],
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de cristal para volver a abrir la ventana de información del
/// laboratorio una vez cerrada.
class LabInfoButton extends StatelessWidget {
  final VoidCallback onTap;

  const LabInfoButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 26,
        blur: 12,
        tint: _kLabTint,
        tintStrength: 3.2,
        uniform: true,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text(
              'Información',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de cristal para salir del laboratorio y volver al pasillo.
class LabExitButton extends StatelessWidget {
  final VoidCallback onTap;

  const LabExitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 26,
        blur: 12,
        tint: _kLabTint,
        tintStrength: 3.2,
        uniform: true,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.highlight, size: 20),
            SizedBox(width: 8),
            Text(
              'Salir',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ventana flotante completa con la información detallada del laboratorio:
/// foto de referencia, encargado y contacto, descripción y horarios por día
/// (módulo, materia, grupo y profesor).
class LabDetailPanel extends StatefulWidget {
  final LabInfo lab;

  /// Horarios del laboratorio (puede estar vacío si aún no se capturan).
  final List<LabSchedule> schedules;

  /// Si es null no se muestra el botón de cerrar (panel anclado a la pared).
  final VoidCallback? onClose;

  /// Desenfoque del fondo. Dentro de un hotspot del panorama (con
  /// transformaciones 3D) usar 0: el cristal queda solo con tinte y borde.
  final double blur;

  const LabDetailPanel({
    super.key,
    required this.lab,
    required this.schedules,
    this.onClose,
    this.blur = 16,
  });

  @override
  State<LabDetailPanel> createState() => _LabDetailPanelState();
}

class _LabDetailPanelState extends State<LabDetailPanel> {
  late String _day;

  @override
  void initState() {
    super.initState();
    final today = currentDayName();
    _day = kWeekDays.contains(today) ? today : kWeekDays.first;
  }

  static int _minutes(String t) {
    final p = t.split(':');
    if (p.length < 2) return 0;
    return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
  }

  /// Número de módulo (bloques de 50 min desde las 08:00), si el horario cuadra.
  static String _module(String start) {
    final m = _minutes(start) - 8 * 60;
    if (m < 0 || m % 50 != 0) return '';
    return 'Módulo ${m ~/ 50 + 1}';
  }

  Future<void> _mail(String address) async {
    final uri = Uri(scheme: 'mailto', path: address);
    try {
      await launchUrl(uri);
    } catch (_) {
      // Sin cliente de correo disponible: no hay nada más que hacer.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lab = widget.lab;
    final maxHeight = MediaQuery.of(context).size.height * 0.74;
    final entries = [
      for (final s in widget.schedules) ...s.entries,
    ].where((e) => e.day == _day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
      child: GlassContainer(
        radius: 28,
        blur: widget.blur,
        tint: _kLabTint,
        tintStrength: widget.blur == 0 ? 3.8 : 3.4,
        uniform: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 6),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.highlight.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.science, color: AppColors.highlight, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LABORATORIO',
                          style: TextStyle(
                            color: AppColors.highlight,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lab.name,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    )
                  else
                    const SizedBox(width: 10),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto de referencia
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image.asset(
                          lab.imageThumbnail,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Encargado
                    _InfoTile(icon: Icons.person_rounded, label: 'ENCARGADO', value: lab.inCharge),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.mail_rounded,
                      label: 'CONTACTO',
                      value: lab.contact,
                      onTap: () => _mail(lab.contact),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      lab.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: AppColors.highlight, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'HORARIOS',
                          style: TextStyle(
                            color: AppColors.highlight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _DayPicker(
                      selected: _day,
                      onChanged: (d) => setState(() => _day = d),
                    ),
                    const SizedBox(height: 12),
                    if (entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: Text(
                            'No hay clases programadas\nen este laboratorio para este día.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 12.5),
                          ),
                        ),
                      )
                    else
                      for (final e in entries) ...[
                        _ScheduleTile(entry: e, module: _module(e.startTime)),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: onTap != null ? AppColors.accent : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _DayPicker({required this.selected, required this.onChanged});

  static String _short(String day) => day.substring(0, 3);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in kWeekDays)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: day == selected
                      ? LinearGradient(
                          colors: [
                            AppColors.highlight.withValues(alpha: 0.95),
                            AppColors.highlight.withValues(alpha: 0.65),
                          ],
                        )
                      : null,
                  color: day == selected ? null : Colors.white.withValues(alpha: 0.07),
                  border: Border.all(color: Colors.white.withValues(alpha: day == selected ? 0.5 : 0.12)),
                ),
                child: Text(
                  _short(day),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: day == selected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: day == selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final ScheduleEntry entry;
  final String module;

  const _ScheduleTile({required this.entry, required this.module});

  @override
  Widget build(BuildContext context) {
    final now = isScheduleEntryNow(entry);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: now ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: now ? AppColors.highlight.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.startTime,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                Text(entry.endTime, style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
                if (module.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    module,
                    style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.subject,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.2),
                      ),
                    ),
                    if (now)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.highlight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'AHORA',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (entry.group.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Grupo ${entry.group}',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            entry.teacher,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
