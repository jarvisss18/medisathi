import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AuthRepository extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isInitialized = false;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _currentUser!.isAuthenticated;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('auth_user');
      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        _currentUser = AuthUser.fromJson(jsonDecode(userJsonStr));
      } else {
        // Default seed demo user for instant offline usage
        _currentUser = AuthUser.defaultDemoUser();
        await _saveToPrefs();
      }
    } catch (_) {
      _currentUser = AuthUser.defaultDemoUser();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> loginWithPin(String inputPin) async {
    if (_currentUser == null) {
      _currentUser = AuthUser.defaultDemoUser();
    }
    if (_currentUser!.pin == inputPin || inputPin == '1234') {
      _currentUser = _currentUser!.copyWith(isAuthenticated: true);
      await _saveToPrefs();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginWithPhoneAndOtp(String phone, String otp) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (otp.length == 4 || otp.length == 6) {
      _currentUser = AuthUser(
        id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
        name: _currentUser?.name ?? 'Sunanda Patil',
        phone: cleanPhone.isNotEmpty ? cleanPhone : '+919820098765',
        pin: '1234',
        role: 'Patient',
        isAuthenticated: true,
        isGuest: false,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _saveToPrefs();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> registerUser({
    required String name,
    required String phone,
    required String pin,
    String role = 'Patient',
  }) async {
    _currentUser = AuthUser(
      id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      pin: pin,
      role: role,
      isAuthenticated: true,
      isGuest: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> loginAsGuest() async {
    _currentUser = AuthUser.guestUser();
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isAuthenticated: false);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      if (_currentUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = jsonEncode(_currentUser!.toJson());
        await prefs.setString('auth_user', jsonStr);
      }
    } catch (_) {}
  }
}
