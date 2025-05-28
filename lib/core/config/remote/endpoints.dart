import 'dart:io';

import 'package:flutter/foundation.dart';

import 'app_enviroment.dart';

class Endpoints {
  static final Endpoints _singleton = Endpoints._internal();
  factory Endpoints() => _singleton;
  Endpoints._internal();

  String get _endpointLocal {
    if (kIsWeb) {
      return 'http://localhost:59986/'; // o tu endpoint de desarrollo web
    }

    // Solo accede a Platform si no estás en Web
    // Usa try-catch si te preocupa que esto se llame en Web por error
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:7071'; // Android Emulator
      } else {
        return 'http://localhost:7071'; // iOS / Desktop
      }
    } catch (_) {
      return 'http://localhost:7071'; // fallback
    }
  }

  late String endpoint;

  void init() {
    final releaseType = AppEnvironment().releaseType;
    endpoint = switch (releaseType) {
      ReleaseType.local => _endpointLocal,
      ReleaseType.dev => 'https://api-dev.yourdomain.com',
      ReleaseType.test => 'https://api-test.yourdomain.com',
      ReleaseType.prod => 'https://api.yourdomain.com',
    };
  }
}
