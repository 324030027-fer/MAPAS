import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const _keyLoggedIn = 'auth_logged_in';
  static const _keyIsAdmin = 'auth_is_admin';
  static const _keyUserName = 'auth_user_name';

  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String _userName = '';
  bool _isReady = false;
  bool _previewAsStudent = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  String get userName => _userName;
  bool get isReady => _isReady;
  bool get previewAsStudent => _previewAsStudent;
  bool get showAdminTools => _isAdmin && !_previewAsStudent;

  String get roleLabel {
    if (_previewAsStudent) return 'Vista estudiante (admin)';
    if (_isAdmin) return 'Administrador';
    return 'Estudiante / Invitado';
  }

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _isAdmin = prefs.getBool(_keyIsAdmin) ?? false;
    _userName = prefs.getString(_keyUserName) ?? '';
    _isReady = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, _isLoggedIn);
    await prefs.setBool(_keyIsAdmin, _isAdmin);
    await prefs.setString(_keyUserName, _userName);
  }

  Future<void> login(String name) async {
    _isLoggedIn = true;
    _isAdmin = false;
    _previewAsStudent = false;
    _userName = name.trim().isEmpty ? 'Invitado' : name.trim();
    await _persist();
    notifyListeners();
  }

  Future<bool> loginAdmin(String username, String password) async {
    if (username == 'admin' && password == 'admin123') {
      _isLoggedIn = true;
      _isAdmin = true;
      _previewAsStudent = false;
      _userName = 'Administrador';
      await _persist();
      notifyListeners();
      return true;
    }
    return false;
  }

  void setPreviewAsStudent(bool value) {
    if (!_isAdmin) return;
    _previewAsStudent = value;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _isAdmin = false;
    _previewAsStudent = false;
    _userName = '';
    await _persist();
    notifyListeners();
  }
}
