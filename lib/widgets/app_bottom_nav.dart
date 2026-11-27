import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'brand.dart';
import 'glass.dart';

/// Secciones principales (ícono, nombre). Las usan la barra inferior del
/// teléfono y la barra lateral de tableta/PC.
const kNavItems = [
  (Icons.map_rounded, 'Mapa'),
  (Icons.vrpano_rounded, 'Recorridos'),
  (Icons.calendar_month_rounded, 'Escolar'),
  (Icons.apps_rounded, 'Más'),
];

/// Barra lateral (tableta y PC): misma estética que la inferior, fija a la
/// izquierda para no tapar el contenido.
class AppSideNav extends StatelessWidget {
  const AppSideNav({super.key, required this.selectedIndex, required this.onTap, this.isAdmin = false});
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  static const double width = 92;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isAdmin ? AppColors.admin : AppColors.accent;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final idle = isDark ? Colors.white60 : AppColors.textSecondaryLight;
    final active = isAdmin ? AppColors.admin : (isDark ? AppColors.highlight : AppColors.accentOnLight);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Color.lerp(bg, isDark ? Colors.black : Colors.white, 0.18),
        border: Border(right: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 18),
            const BrandMark(size: 48),
            const SizedBox(height: 26),
            for (var i = 0; i < kNavItems.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Semantics(
                  button: true,
                  selected: i == selectedIndex,
                  label: kNavItems[i].$2,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: 72,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        // Activa: relleno ámbar suave + borde ámbar (componente de Figma).
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: i == selectedIndex ? accent.withValues(alpha: isDark ? 0.2 : 0.16) : Colors.transparent,
                          border: Border.all(color: i == selectedIndex ? accent : Colors.transparent),
                        ),
                        child: Column(
                          children: [
                            Icon(kNavItems[i].$1, size: 24, color: i == selectedIndex ? active : idle),
                            const SizedBox(height: 4),
                            Text(
                              kNavItems[i].$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: i == selectedIndex ? FontWeight.w800 : FontWeight.w500,
                                color: i == selectedIndex ? active : idle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  static const _items = kNavItems;

  static const double _height = 66;
  static const double _maxWidth = 400;
  static const double _inset = 6;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isAdmin ? AppColors.admin : AppColors.accent;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassContainer(
                radius: 34,
                blur: 14,
                uniform: true,
                tintStrength: 1.35,
                height: _height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slotWidth = (constraints.maxWidth - _inset * 2) / _items.length;
                    return Stack(
                      children: [
                        // Burbuja de selección que se desliza entre opciones.
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          left: _inset + slotWidth * selectedIndex,
                          top: _inset,
                          bottom: _inset,
                          width: slotWidth,
                          child: DecoratedBox(
                            // Mismo estilo que la barra lateral: ámbar suave + borde.
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: accent.withValues(alpha: isDark ? 0.2 : 0.16),
                              border: Border.all(color: accent),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: _inset),
                          child: Row(
                            children: [
                              for (var i = 0; i < _items.length; i++)
                                Expanded(child: _item(context, i, isDark)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, bool isDark) {
    final selected = selectedIndex == index;
    final (icon, label) = _items[index];
    final idle = isDark ? Colors.white60 : AppColors.textSecondaryLight;
    final active = isAdmin ? AppColors.admin : (isDark ? AppColors.highlight : AppColors.accentOnLight);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedScale(
            scale: selected ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: selected ? active : idle),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.2,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? active : idle,
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
