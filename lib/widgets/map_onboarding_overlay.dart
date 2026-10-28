import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/onboarding_provider.dart';

class MapOnboardingOverlay extends StatefulWidget {
  const MapOnboardingOverlay({super.key});

  @override
  State<MapOnboardingOverlay> createState() => _MapOnboardingOverlayState();
}

class _MapOnboardingOverlayState extends State<MapOnboardingOverlay> {
  int _step = 0;

  static const _steps = [
    (Icons.pinch, 'Haz zoom', 'Pellizca o usa dos dedos para acercar el mapa del campus.'),
    (Icons.touch_app, 'Explora edificios', 'Toca un pin para ver fotos, laboratorios y horarios.'),
    (Icons.vrpano, 'Recorridos 360°', 'En la pestaña Recorridos entra al tour virtual del LT.'),
  ];

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();
    if (!onboarding.loaded || onboarding.completed) return const SizedBox.shrink();

    final (icon, title, body) = _steps[_step];

    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => onboarding.markCompleted(),
                  child: const Text('Omitir', style: TextStyle(color: Colors.white70)),
                ),
              ),
              const Spacer(),
              Icon(icon, size: 72, color: AppColors.accent),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _step ? AppColors.accent : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (_step < _steps.length - 1) {
                      setState(() => _step++);
                    } else {
                      await onboarding.markCompleted();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_step < _steps.length - 1 ? 'Siguiente' : '¡Listo!'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
