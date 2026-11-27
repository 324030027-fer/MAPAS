import 'package:flutter/material.dart';

/// Puntos de quiebre del diseño responsive.
///  - teléfono: < 700
///  - tableta:  700 – 1099
///  - PC:       >= 1100
class Breakpoints {
  static const tablet = 700.0;
  static const desktop = 1100.0;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= tablet;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;
}

/// Anchos máximos de lectura para que el contenido no se estire en pantallas
/// grandes. En el teléfono no cambian nada (el ancho ya es menor).
class ContentWidth {
  static const form = 480.0; // login, formularios cortos
  static const page = 760.0; // listas y pantallas de texto
  static const wide = 1100.0; // galerías
}

/// Espacio que hay que dejar abajo para que la barra de navegación flotante
/// (solo en teléfono) no tape el contenido. En tableta/PC la barra es lateral.
double navBarInset(BuildContext context) =>
    Breakpoints.isWide(context) ? 24 : 96 + MediaQuery.paddingOf(context).bottom;

/// Centra a su hijo y lo limita a [maxWidth].
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = ContentWidth.page});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Relleno horizontal para listas: deja el contenido de [maxWidth] centrado
/// pero el scroll ocupa todo el ancho (se puede desplazar desde los costados).
EdgeInsets centeredListPadding(
  BuildContext context, {
  double maxWidth = ContentWidth.page,
  double horizontal = 20,
  double top = 16,
  double bottom = 100,
}) {
  final w = MediaQuery.sizeOf(context).width;
  final side = w > maxWidth + horizontal * 2 ? (w - maxWidth) / 2 : horizontal;
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}
