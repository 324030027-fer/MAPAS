import 'package:flutter/material.dart';

/// Nombre y lema de la app.
const kAppName = 'WOLF-MAP';
const kAppTagline = 'Dejando huella';

/// Azul de la marca WOLF-MAP (solo para el logo; la interfaz sigue en ámbar).
const kBrandBlue = Color(0xFF1E90FF);

/// Símbolo del lobo sobre un cuadro oscuro. El lobo es blanco, así que el
/// fondo oscuro lo mantiene visible también en modo claro.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48, this.radius});
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E131C),
        borderRadius: BorderRadius.circular(radius ?? size * 0.28),
        border: Border.all(color: kBrandBlue.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: kBrandBlue.withValues(alpha: 0.22), blurRadius: size * 0.4, spreadRadius: -2)],
      ),
      child: Image.asset('assets/wolf_mark.png', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
    );
  }
}

/// Logo completo (símbolo + WOLF-MAP + lema). Pensado para fondos oscuros.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 140});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/wolf_map.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: '$kAppName, $kAppTagline',
    );
  }
}
