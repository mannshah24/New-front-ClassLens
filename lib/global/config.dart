import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {

  AppConfig._();

  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:8000/api';
}