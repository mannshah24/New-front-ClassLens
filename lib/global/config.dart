import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    // 1. First check build-time environment variable compilation
    const buildTimeUrl = String.fromEnvironment('BASE_URL');
    if (buildTimeUrl.isNotEmpty) {
      return buildTimeUrl;
    }

    // 2. Backward compatibility fallback to runtime dotenv if assets exist
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    if (Platform.isAndroid) {
      // Android emulator routes host machine through 10.0.2.2
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }
}