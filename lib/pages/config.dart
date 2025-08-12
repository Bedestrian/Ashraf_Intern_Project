import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String webApiUrl = '';
  static const String webRobotUrl = '';

  static Future<String?> get apiUrl async {
    if (kIsWeb) {
      return webApiUrl.isNotEmpty ? webApiUrl : Uri.base.origin;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('pocketbase_url');
    }
  }

  static Future<String?> get robotApiUrl async {
    if (kIsWeb) {
      return webRobotUrl.isNotEmpty ? webRobotUrl : Uri.base.origin;
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('robot_url');
    }
  }
}