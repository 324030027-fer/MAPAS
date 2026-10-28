import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'glass.dart';

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

  static const _items = [
    (Icons.map_rounded, 'Mapa'),
    (Icons.vrpano_rounded, 'Recorridos'),
    (Icons.apps_rounded, 'Más'),
  ];

  static const double _height = 66;
  static const double _maxWidth = 320;
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
                blur: 24,
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
                          duration: const Duration(milliseconds: 380),
                          curve: Curves.easeOutBack,
                          left: _inset + slotWidth * selectedIndex,
                          top: _inset,
                          bottom: _inset,
                          width: slotWidth,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: isDark ? 0.42 : 0.50),
                                  accent.withValues(alpha: isDark ? 0.16 : 0.22),
                                ],
                              ),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.45),
                                  blurRadius: 18,
                                  spreadRadius: -2,
                                ),
                              ],
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
    final idle = isDark ? Colors.white70 : const Color(0xFF3B3B52);
    final active = isDark ? Colors.white : const Color(0xFF111122);

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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
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
