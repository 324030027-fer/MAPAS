import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'glass.dart';

/// Altura (grados bajo el horizonte) a la que se colocan las flechas del
/// recorrido: sobre el piso del pasillo, para no ocupar el centro de la vista.
const double kTourArrowPitch = -22;

/// Inclinación (radianes) con la que la flecha "se recuesta" sobre el piso.
const double _kFloorTilt = 0.6;

/// Flecha del recorrido: disco pequeño de cristal con un chevron, recostado
/// sobre el piso. Si [label] no es null (entradas y baños) muestra debajo una
/// etiqueta de cristal con el nombre del destino.
///
/// Va dentro de un hotspot del panorama (con transformaciones 3D), por eso el
/// cristal es solo tinte, borde y brillo, sin desenfoque del fondo.
class TourArrow extends StatelessWidget {
  final String? label;
  final VoidCallback onTap;

  const TourArrow({super.key, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Align(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(_kFloorTilt),
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.46),
                      Colors.white.withValues(alpha: 0.12),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.75), width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                  size: 46,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 4),
              GlassTag(
                radius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
