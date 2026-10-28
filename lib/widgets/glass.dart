import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Contenedor "liquid glass": desenfoque del fondo, tinte translúcido,
/// borde con brillo especular y sombra suave.
class GlassContainer extends StatelessWidget {
  final Widget? child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final double tintStrength;
  final bool uniform;
  final bool shadow;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    this.child,
    this.radius = 24,
    this.blur = 18,
    this.padding,
    this.margin,
    this.tint,
    this.tintStrength = 1,
    this.uniform = false,
    this.shadow = true,
    this.borderRadius,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final br = borderRadius ?? BorderRadius.circular(radius);
    final base = tint ?? (isDark ? Colors.white : Colors.white);

    final topAlpha = (isDark ? 0.20 : 0.62) * tintStrength;
    final bottomAlpha = uniform ? topAlpha : (isDark ? 0.07 : 0.30) * tintStrength;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  base.withValues(alpha: topAlpha),
                  base.withValues(alpha: bottomAlpha),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.7),
                width: 1,
              ),
            ),
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      ),
    );
  }
}

/// Versión ligera sin desenfoque (para muchos elementos pequeños, como las
/// etiquetas de los pines, donde un BackdropFilter por elemento sería costoso).
class GlassTag extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  const GlassTag({
    super.key,
    required this.child,
    this.radius = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E2C).withValues(alpha: 0.55),
            const Color(0xFF1E1E2C).withValues(alpha: 0.35),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: child,
    );
  }
}

/// Fondo con degradado y "orbes" de color para que el cristal tenga algo
/// que desenfocar en pantallas sin imagen (Recorridos, Más, Login...).
class GlassBackdrop extends StatelessWidget {
  final Widget child;

  const GlassBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1B1A33), bg, const Color(0xFF14202E)]
                  : [const Color(0xFFE8EEFF), bg, const Color(0xFFE3F6FA)],
            ),
          ),
        ),
        _orb(const Alignment(-1.0, -0.8), 320, AppColors.primary, isDark ? 0.45 : 0.28),
        _orb(const Alignment(1.1, -0.1), 280, AppColors.accent, isDark ? 0.28 : 0.22),
        _orb(const Alignment(-0.6, 1.0), 300, AppColors.highlight, isDark ? 0.22 : 0.18),
        child,
      ],
    );
  }

  Widget _orb(Alignment alignment, double size, Color color, double alpha) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de cristal para listas (reemplazo de [Card]).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? tint;
  final double tintStrength;

  const GlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 10),
    this.radius = 20,
    this.tint,
    this.tintStrength = 1,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: margin,
      radius: radius,
      blur: 16,
      tint: tint,
      tintStrength: tintStrength,
      // Material transparente para que ListTile/InkWell dibujen su efecto
      // por encima del cristal.
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// [Scaffold] con el fondo de cristal. Con [forceDark] fuerza el tema oscuro
/// (para pantallas con colores de texto claros fijos).
class GlassScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;
  final bool forceDark;

  const GlassScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset,
    this.forceDark = false,
    // Se ignora: el fondo lo da GlassBackdrop.
    Color? backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = GlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      ),
    );
    if (forceDark) content = Theme(data: AppTheme.dark, child: content);
    return content;
  }
}
