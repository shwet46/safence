import 'package:flutter/material.dart';
import 'package:safence/utils/constants.dart';

import 'package:jwt_decode/jwt_decode.dart'; 

// class User {
//   final String id;
//   final String name;
//   User({required this.id, required this.name});
//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(id: json['id'], name: json['name']);
//   }
// }

class AuthProvider with ChangeNotifier {
  static const _storage = Constants.secureStorage;
  bool _isAuthenticated = false; 
  bool _isAuthCheckComplete = false;

  AuthProvider() { 
    _checkLoginStatus();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthCheckComplete => _isAuthCheckComplete;

  Future<void> login(String token) async {
    try {
      await _storage.write(key: 'jwt', value: token);
      _isAuthenticated = true;
      // Map<String, dynamic> payload = Jwt.parseJwt(token);
      // _user = User.fromJson(payload);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      String? token = await _storage.read(key: 'jwt');
      if (token != null) {
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
      _isAuthenticated = false;
    } finally {
      _isAuthCheckComplete = true;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: 'jwt');
      _isAuthenticated = false;
      // _user = null;
      // 4. Removed redundant call to checkLoginStatus()
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }

  Future<bool> _isLoggedIn() async {
    try {
      String? jwt = await _storage.read(key: 'jwt');
      if (jwt == null) {
        return false;
      }
      return !Jwt.isExpired(jwt);
    } catch (e) {
      debugPrint('Error reading token: $e');
      return false;
    }
  }
}