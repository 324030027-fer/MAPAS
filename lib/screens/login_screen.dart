import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/glass.dart';
import '../widgets/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _signingIn = false;

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
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return GlassScaffold(
      forceDark: true,
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: centeredListPadding(context, maxWidth: ContentWidth.form, horizontal: 24, top: 24, bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ========== LOGO UNIVERSIDAD (arriba, más grande) ==========
                Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),

                // ========== CÍRCULO CON LOGO DE LA APP ==========
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A33D).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logoapp.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback si no encuentra la imagen
                        return Container(
                          width: 100,
                          height: 100,
                          color: AppColors.primary,
                          child: const Icon(
                            Icons.map_rounded,
                            color: AppColors.onAccent,
                            size: 60,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ========== TÍTULO GLORIOSO ==========
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE8A33D), Color(0xFFE8A33D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'NULLCORE MAPS',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Campus UPJR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // ========== COMUNIDAD UPJR (cuenta institucional) ==========
                GlassCard(
                  radius: 28,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.school_outlined, color: Color(0xFFE8A33D)),
                            SizedBox(width: 12),
                            Text(
                              'COMUNIDAD UPJR',
                              style: TextStyle(
                                color: Color(0xFFE8A33D),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Alumnos y personal: entra con tu correo @upjr.edu.mx para ver profesores, horarios y trámites.',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _signingIn ? null : () => _signInUpjr(auth),
                            icon: _signingIn
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                                  )
                                : const Icon(Icons.login),
                            label: const Text('INICIAR SESIÓN CON GOOGLE (UPJR)'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1B2230),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                        if (!auth.supportsGoogleSignIn) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'En la app de escritorio aún no está disponible; usa la versión web o la del celular.',
                            style: TextStyle(color: Colors.white54, fontSize: 11.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ========== SECCIÓN INVITADO (nombre obligatorio) ==========
                GlassCard(
                  radius: 28,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: Color(0xFFE8A33D)),
                            const SizedBox(width: 12),
                            const Text(
                              'ASPIRANTES Y VISITANTES',
                              style: TextStyle(
                                color: Color(0xFFE8A33D),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Tu nombre (obligatorio)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFE8A33D)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final name = _nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor ingresa tu nombre'),
                                    backgroundColor: AppColors.darkSurface,
                                  ),
                                );
                                return;
                              }
                              await auth.login(name);
                              if (context.mounted) context.go('/');
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('INGRESAR COMO INVITADO'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE8A33D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Aviso de privacidad (datos personales del invitado).
                        const Text(
                          'Tu nombre solo se usa para saludarte y se guarda únicamente en este '
                          'dispositivo; no se envía a ningún servidor. Puedes borrarlo al cerrar sesión.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
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
