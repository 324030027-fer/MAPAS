import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/brand.dart';

/// Inicio de sesión: el mapa del campus de fondo, una acción principal
/// (cuenta UPJR) y la de invitado que se despliega solo si se elige.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  bool _signingIn = false;
  bool _guestOpen = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInUpjr(AuthProvider auth) async {
    setState(() => _signingIn = true);
    try {
      await auth.signInWithGoogle();
      if (mounted) context.go('/');
    } on AuthFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _enterAsGuest(AuthProvider auth) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Escribe tu nombre para continuar');
      return;
    }
    await auth.login(name);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900;

    final card = _LoginCard(
      signingIn: _signingIn,
      supportsGoogle: auth.supportsGoogleSignIn,
      guestOpen: _guestOpen,
      nameController: _nameController,
      nameError: _nameError,
      onGoogle: () => _signInUpjr(auth),
      onOpenGuest: () => setState(() => _guestOpen = true),
      onGuest: () => _enterAsGuest(auth),
      onNameChanged: () {
        if (_nameError != null) setState(() => _nameError = null);
      },
      showBrand: !wide,
    );

    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo: el campus desde arriba, desenfocado y oscurecido.
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image.asset('assets/mapa_base.jpg', fit: BoxFit.cover, cacheWidth: 1200),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkBg.withValues(alpha: 0.55),
                    AppColors.darkBg.withValues(alpha: 0.85),
                    AppColors.darkBg,
                  ],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: wide
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1040),
                          child: Row(
                            children: [
                              const Expanded(child: _Hero()),
                              const SizedBox(width: 56),
                              SizedBox(width: 420, child: card),
                            ],
                          ),
                        )
                      : ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: card),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje de bienvenida (solo PC, a la izquierda de la tarjeta).
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/logo.png', height: 64),
        const SizedBox(height: 36),
        const Text(
          'Encuentra cualquier\nsalón del campus\nen segundos.',
          style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.8),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mapa interactivo, recorridos 360°, calendario escolar\ny contacto con tus profesores.',
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Feature(icon: Icons.map_rounded, label: 'Mapa'),
            _Feature(icon: Icons.threesixty_rounded, label: 'Salones en 360°'),
            _Feature(icon: Icons.calendar_month_rounded, label: 'Calendario'),
          ],
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.signingIn,
    required this.supportsGoogle,
    required this.guestOpen,
    required this.nameController,
    required this.nameError,
    required this.onGoogle,
    required this.onOpenGuest,
    required this.onGuest,
    required this.onNameChanged,
    required this.showBrand,
  });

  final bool signingIn, supportsGoogle, guestOpen, showBrand;
  final TextEditingController nameController;
  final String? nameError;
  final VoidCallback onGoogle, onOpenGuest, onGuest, onNameChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF263042).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: BrandLogo(height: 150)),
              if (showBrand) ...[
                const SizedBox(height: 6),
                const Text(
                  'Encuentra cualquier salón del campus en segundos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: signingIn || !supportsGoogle ? null : onGoogle,
                icon: signingIn
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onAccent))
                    : const Icon(Icons.school_rounded),
                label: const Text('Entrar con mi cuenta UPJR'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  disabledBackgroundColor: Colors.white12,
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                supportsGoogle
                    ? 'Con tu correo @upjr.edu.mx: profesores y trámites.'
                    : 'Disponible en la versión web y en el celular.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('¿Aspirante o visitante?', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.white12)),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: !guestOpen
                    ? OutlinedButton.icon(
                        onPressed: onOpenGuest,
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Entrar como invitado'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: nameController,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.go,
                            onSubmitted: (_) => onGuest(),
                            onChanged: (_) => onNameChanged(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '¿Cómo te llamas?',
                              errorText: nameError,
                              prefixIcon: const Icon(Icons.person_outline_rounded),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: onGuest,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.darkBg,
                              minimumSize: const Size.fromHeight(50),
                              textStyle: const TextStyle(fontWeight: FontWeight.w800),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Entrar'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tu nombre solo se guarda en este dispositivo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white38, fontSize: 11.5),
                          ),
                        ],
                      ),
              ),
              if (showBrand) ...[
                const SizedBox(height: 22),
                Center(child: Image.asset('assets/logo.png', height: 34)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
