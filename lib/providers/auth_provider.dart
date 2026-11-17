import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quién usa la app.
/// - [guest]: aspirantes y visitantes; solo ven la información pública.
/// - [student]: comunidad UPJR (cuenta Google @upjr.edu.mx); ven profesores,
///   horarios, trámites, etc.
/// - [admin]: cuenta UPJR registrada en la colección `admins` de Firestore;
///   además gestiona el contenido.
enum UserRole { guest, student, admin }

/// Error de inicio de sesión con un mensaje listo para mostrar.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthProvider extends ChangeNotifier {
  /// Dominio institucional permitido.
  static const allowedDomain = 'upjr.edu.mx';

  // El invitado no tiene cuenta: solo se recuerda su nombre en el dispositivo.
  static const _keyGuest = 'auth_guest';
  static const _keyGuestName = 'auth_guest_name';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _sub;

  User? _user; // sesión UPJR (Firebase)
  bool _isGuest = false;
  String _guestName = '';
  bool _isAdmin = false;
  bool _isReady = false;
  bool _previewAsStudent = false;

  bool get isLoggedIn => _user != null || _isGuest;
  bool get isAdmin => _isAdmin;
  bool get isReady => _isReady;
  bool get previewAsStudent => _previewAsStudent;
  bool get showAdminTools => _isAdmin && !_previewAsStudent;
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;

  String get userName {
    if (_user != null) return _user!.displayName ?? _user!.email ?? 'Estudiante UPJR';
    return _guestName.isEmpty ? 'Invitado' : _guestName;
  }

  UserRole get role => _user == null ? UserRole.guest : (_isAdmin ? UserRole.admin : UserRole.student);

  /// Puede ver la información interna (profesores, horarios, trámites…).
  /// Esto oculta pantallas; la protección real de los datos la dan las
  /// reglas de Firestore (solo cuentas @upjr.edu.mx pueden leerlos).
  bool get canSeePrivate => role != UserRole.guest;

  String get roleLabel {
    if (_previewAsStudent) return 'Vista estudiante (admin)';
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.student:
        return 'Comunidad UPJR';
      case UserRole.guest:
        return 'Invitado';
    }
  }

  /// El inicio de sesión con Google funciona en web, Android e iOS. En
  /// Windows/macOS/Linux el plugin de Firebase aún no lo soporta.
  bool get supportsGoogleSignIn =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool(_keyGuest) ?? false;
    _guestName = prefs.getString(_keyGuestName) ?? '';
    // Firebase recuerda la sesión: el primer evento dice si ya había una.
    _sub = _auth.authStateChanges().listen(_onUser);
  }

  Future<void> _onUser(User? user) async {
    if (user != null && !_isInstitutional(user.email)) {
      // Cuenta ajena a la universidad: no se acepta.
      await _auth.signOut();
      return;
    }
    _user = user;
    _isAdmin = user != null && await _checkAdmin(user.email!);
    if (user == null) _previewAsStudent = false;
    _isReady = true;
    notifyListeners();
  }

  static bool _isInstitutional(String? email) =>
      email != null && email.toLowerCase().endsWith('@$allowedDomain');

  /// Admin = existe el documento `admins/{correo}` en Firestore.
  Future<bool> _checkAdmin(String email) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('admins').doc(email.toLowerCase()).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Inicia sesión con la cuenta Google institucional (@upjr.edu.mx).
  Future<void> signInWithGoogle() async {
    if (!supportsGoogleSignIn) {
      throw AuthFailure('En la app de escritorio aún no se puede iniciar sesión con Google. '
          'Usa la versión web o la del celular.');
    }
    final provider = GoogleAuthProvider()
      // Sugiere a Google mostrar solo cuentas del dominio de la universidad.
      ..setCustomParameters({'hd': allowedDomain, 'prompt': 'select_account'});
    try {
      final cred = kIsWeb ? await _auth.signInWithPopup(provider) : await _auth.signInWithProvider(provider);
      if (!_isInstitutional(cred.user?.email)) {
        await _auth.signOut();
        throw AuthFailure('Usa tu correo institucional @$allowedDomain.');
      }
      await _setGuest(false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled-popup-request' || e.code == 'web-context-canceled') {
        throw AuthFailure('Inicio de sesión cancelado.');
      }
      throw AuthFailure('No se pudo iniciar sesión (${e.code}).');
    }
  }

  /// Entrada como invitado (aspirante o visitante).
  Future<void> login(String name) async {
    _guestName = name.trim();
    _previewAsStudent = false;
    await _setGuest(true);
    notifyListeners();
  }

  Future<void> _setGuest(bool value) async {
    _isGuest = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGuest, value);
    await prefs.setString(_keyGuestName, value ? _guestName : '');
  }

  void setPreviewAsStudent(bool value) {
    if (!_isAdmin) return;
    _previewAsStudent = value;
    notifyListeners();
  }

  Future<void> logout() async {
    _previewAsStudent = false;
    _guestName = '';
    await _setGuest(false);
    if (_user != null) {
      await _auth.signOut(); // dispara _onUser(null)
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
