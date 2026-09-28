import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyModelURL = 'cached_model_url';

  /// Save the avatar model URL locally
  static Future<void> saveModelURL(String modelURL) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModelURL, modelURL);
  }

  /// Get the cached avatar model URL, or null if not saved yet
  static Future<String?> getModelURL() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyModelURL);
  }
}