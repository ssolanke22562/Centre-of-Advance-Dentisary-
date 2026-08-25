import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  AuthService._init();

  static const String _keySession = 'user_session_v1';
  static const int _inactivityTimeoutHours = 8; // Session expiry threshold

  /// Authenticate email & password against salted hashes stored in local SQLite
  Future<UserSession?> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Email and password cannot be empty.');
    }

    final user = await DatabaseHelper.instance.getUserByEmail(cleanEmail);
    if (user == null) {
      throw Exception('Invalid email or password. Please use registered clinic credentials.');
    }

    final isMatch = DatabaseHelper.instance.verifyPassword(
      cleanPassword,
      user.passwordHash,
      user.salt,
    );

    if (!isMatch) {
      throw Exception('Invalid email or password.');
    }

    final session = UserSession(
      email: user.email,
      role: user.role,
      name: user.name,
      loginTime: DateTime.now(),
    );

    await _saveSession(session);
    return session;
  }

  Future<void> _saveSession(UserSession session) async {
    final data = {
      'email': session.email,
      'role': session.role == UserRole.admin ? 'admin' : 'receptionist',
      'name': session.name,
      'login_time': session.loginTime.toIso8601String(),
    };
    await _secureStorage.write(key: _keySession, value: jsonEncode(data));
  }

  /// Retrieve active session with auto-expiry check
  Future<UserSession?> getActiveSession() async {
    try {
      final jsonStr = await _secureStorage.read(key: _keySession);
      if (jsonStr == null) return null;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final loginTime = DateTime.parse(data['login_time'] as String);

      // Check session age
      final difference = DateTime.now().difference(loginTime);
      if (difference.inHours >= _inactivityTimeoutHours) {
        await logout();
        return null;
      }

      return UserSession(
        email: data['email'] as String,
        role: UserRoleExtension.fromString(data['role'] as String),
        name: data['name'] as String,
        loginTime: loginTime,
      );
    } catch (_) {
      await logout();
      return null;
    }
  }

  /// Clears stored session tokens from secure storage
  Future<void> logout() async {
    await _secureStorage.delete(key: _keySession);
  }
}
