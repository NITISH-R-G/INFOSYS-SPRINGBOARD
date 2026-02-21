import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../data/database_helper.dart';

class AuthService extends ChangeNotifier {
  AppUser? _currentUser;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _uuid = const Uuid();

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    // Check for persisted session
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');

    if (userId != null) {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (maps.isNotEmpty) {
        _currentUser = AppUser.fromMap(maps.first);
        notifyListeners();
      }
    }
  }

  Future<void> loginAsClient(String name) async {
    await _loginOrRegister(name, UserRole.client);
  }

  Future<void> loginAsDealer(String name) async {
    await _loginOrRegister(name, UserRole.dealer);
  }

  Future<void> _loginOrRegister(String name, UserRole role) async {
    final db = await _dbHelper.database;
    final email = '${name.toLowerCase().replaceAll(' ', '.')}@example.com';

    // Check if user exists (simplistic "login" by name/email for prototype)
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      _currentUser = AppUser.fromMap(maps.first);
    } else {
      // Register new user
      final newUser = AppUser(
        id: _uuid.v4(),
        email: email,
        name: name,
        role: role,
      );

      await db.insert('users', newUser.toMap());
      _currentUser = newUser;
    }

    // Persist session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', _currentUser!.id);

    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    notifyListeners();
  }
}
