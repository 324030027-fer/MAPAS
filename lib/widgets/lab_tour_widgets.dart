import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/private_data_provider.dart';
import '../models/map_location.dart';
import 'glass.dart';

// Tinte oscuro común de las ventanas de laboratorio (texto blanco encima).
const Color _kLabTint = Color(0xFF222B3A);

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
/// foto de referencia, encargado y contacto, y descripción.
class LabDetailPanel extends StatefulWidget {
  final LabInfo lab;

  /// Si es null no se muestra el botón de cerrar (panel anclado a la pared).
  final VoidCallback? onClose;

  /// Desenfoque del fondo. Dentro de un hotspot del panorama (con
  /// transformaciones 3D) usar 0: el cristal queda solo con tinte y borde.
  final double blur;

  const LabDetailPanel({
    super.key,
    required this.lab,
    this.onClose,
    this.blur = 16,
  });

  @override
  State<LabDetailPanel> createState() => _LabDetailPanelState();
}

class _LabDetailPanelState extends State<LabDetailPanel> {
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
    final canSeePrivate = context.watch<AuthProvider>().canSeePrivate;
    // Encargado y correo vienen de Firestore (solo comunidad UPJR).
    final staff = context.watch<PrivateDataProvider>().labStaffByName(lab.name);
    final maxHeight = MediaQuery.of(context).size.height * 0.74;

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
                    // Encargado y contacto: solo comunidad UPJR.
                    if (canSeePrivate && staff != null) ...[
                      _InfoTile(icon: Icons.person_rounded, label: 'ENCARGADO', value: staff.inCharge),
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.mail_rounded,
                        label: 'CONTACTO',
                        value: staff.contact,
                        onTap: () => _mail(staff.contact),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      lab.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
                    ),
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
