//import 'package:shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String keyUsername = 'username';
  static const String keyIsLoggedIn = 'isLoggedIn';

  // Singleton instance
  static SharedPreferencesHelper? _instance;
  late SharedPreferences _preferences;

  SharedPreferencesHelper._();

  static Future<SharedPreferencesHelper> getInstance() async {
    _instance ??= SharedPreferencesHelper._();
    _instance!._preferences = await SharedPreferences.getInstance();
    return _instance!;
  }

  // User related methods
  Future<bool> saveUserLoginInfo(String username, bool isLoggedIn) async {
    try {
      await _preferences.setString(keyUsername, username);
      await _preferences.setBool(keyIsLoggedIn, isLoggedIn);
      return true;
    } catch (e) {
      print('Error saving user login info: $e');
      return false;
    }
  }

  Future<void> clearUserLoginInfo() async {
    await _preferences.remove(keyUsername);
    await _preferences.setBool(keyIsLoggedIn, false);
  }

  String? getUsername() {
    return _preferences.getString(keyUsername);
  }

  bool isUserLoggedIn() {
    return _preferences.getBool(keyIsLoggedIn) ?? false;
  }
}