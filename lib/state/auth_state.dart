import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthState extends ChangeNotifier {
  static const _usersKey = 'tickethub_users';
  static const _sessionKey = 'tickethub_session_user_id';

  final _uuid = const Uuid();
  List<AppUser> _users = [];
  AppUser? _currentUser;
  bool _isLoading = true;
  String? _error;

  List<AppUser> get users => _users;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> bootstrap() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final usersRaw = prefs.getString(_usersKey);
    if (usersRaw != null) {
      final List decoded = jsonDecode(usersRaw) as List;
      _users = decoded
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (!_users.any((u) => u.role == UserRole.admin)) {
      _users.add(AppUser(
        id: _uuid.v4(),
        name: 'Platform Admin',
        email: 'admin@tickethub.com',
        phone: '0000000000',
        passwordHash: _hash('admin123'),
        role: UserRole.admin,
        createdAt: DateTime.now(),
      ));
      await _persistUsers();
    }

    final sessionId = prefs.getString(_sessionKey);
    if (sessionId != null) {
      final match = _users.where((u) => u.id == sessionId);
      _currentUser = match.isNotEmpty ? match.first : null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persistUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_users.map((u) => u.toJson()).toList());
    await prefs.setString(_usersKey, encoded);
  }

  Future<void> _persistSession(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, userId);
    }
  }

  String _hash(String raw) {
    // Lightweight obfuscation for local/demo storage.
    // Replace with a real hashing + backend auth service for production.
    final bytes = raw.codeUnits;
    final sum = bytes.fold<int>(0, (a, b) => a + b);
    return '${raw.length}-$sum-${raw.hashCode}';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$').hasMatch(email);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _error = null;

    if (name.trim().isEmpty || phone.trim().isEmpty) {
      _error = 'Please fill in all fields.';
      notifyListeners();
      return false;
    }
    if (!_isValidEmail(email)) {
      _error = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _error = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }
    final exists = _users.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    if (exists) {
      _error = 'An account with this email already exists.';
      notifyListeners();
      return false;
    }

    final user = AppUser(
      id: _uuid.v4(),
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      passwordHash: _hash(password),
      role: role,
      createdAt: DateTime.now(),
    );

    _users.add(user);
    await _persistUsers();

    _currentUser = user;
    await _persistSession(user.id);

    notifyListeners();
    return true;
  }

  Future<bool> login({required String email, required String password}) async {
    _error = null;

    final matches = _users.where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );

    if (matches.isEmpty) {
      _error = 'No account found with this email.';
      notifyListeners();
      return false;
    }

    final user = matches.first;
    if (user.passwordHash != _hash(password)) {
      _error = 'Incorrect password. Please try again.';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    await _persistSession(user.id);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _persistSession(null);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}