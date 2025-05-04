import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

String getApiUrl() {
  if (kIsWeb) {
    // Use --dart-define for web
    return const String.fromEnvironment('API_URL', defaultValue: 'https://default.example.com');
  } else {
    // Use dotenv for mobile/desktop
    return dotenv.env['API_URL'] ?? 'https://default.example.com';
  }
} 