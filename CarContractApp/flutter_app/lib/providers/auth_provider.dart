import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// Authentication provider with proper JWT lifecycle management.
///
/// Features:
/// - Stores JWT in SharedPreferences
/// - Validates token on app start via /api/auth/me
/// - Exposes getToken() for other services
/// - Handles 401 responses by triggering logout
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  // User Model Details
  String? _userId;
  String? _email;
  String? _fullName;
  String? _role;
  String? _token;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get role => _role;
  String? get fullName => _fullName;
  String? get email => _email;
  String? get userId => _userId;

  /// Public getter for the JWT token — used by ApiService and other providers
  String? get token => _token;

  AuthProvider() {
    _loadUser();
  }

  /// Get the stored token (async version)
  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');

    if (storedToken != null && storedToken.isNotEmpty) {
      try {
        final userData = await _authService.getCurrentUser(storedToken);
        _isAuthenticated = true;
        _token = storedToken;
        _userId = userData['id'].toString();
        _email = userData['email'];
        _fullName = userData['full_name'];
        _role = userData['role'];
      } catch (e) {
        // Token invalid or expired — clear it
        _isAuthenticated = false;
        _token = null;
        await prefs.remove('auth_token');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);

      if (response != null && response.containsKey('access_token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response['access_token']);
        _token = response['access_token'];

        // Load user details
        await _loadUser();
        return true;
      } else {
        _error = "Invalid login response";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String email,
    String password,
    String fullName,
    String role,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.register(
        email,
        password,
        fullName,
        role,
      );
      if (success) {
        // Auto-login after registration
        return await login(email, password);
      } else {
        _error = "Registration failed";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Handle 401 responses from the API — triggers logout
  void handleAuthExpired(BuildContext? context) {
    logout();
    if (context != null) {
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please log in again.'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _email = null;
    _fullName = null;
    _role = null;

    notifyListeners();
  }

  /// Clear any displayed errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
