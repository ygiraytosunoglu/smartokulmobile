import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/shared_preferences.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoggedIn = false;
  late SharedPreferencesHelper _prefsHelper;
  final _apiService = ApiService();

  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  UserProvider() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefsHelper = await SharedPreferencesHelper.getInstance();
    _isLoggedIn = _prefsHelper.isUserLoggedIn();
    notifyListeners();
  }

  Future<void> login(String tckn, String pin) async {
    try {
      final user = await _apiService.validatePerson(tckn, pin);
      _user = user;
      _isLoggedIn = true;
      await _prefsHelper.saveUserLoginInfo(user.tckn, true);
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      rethrow;
    }
  }

  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    await _prefsHelper.clearUserLoginInfo();
    notifyListeners();
  }

  void setUser(User user) {
    _user = user;
    _isLoggedIn = true;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }
} 