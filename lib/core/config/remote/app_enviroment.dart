import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:yaml/yaml.dart';

import '../firebase/firebase_options_dev.dart' as dev;
// import '/config/firebase/firebase_options_test.dart' as test;
import '../firebase/firebase_options_prod.dart' as prod;
// import '/config/firebase/firebase_options_local.dart' as local;

enum ReleaseType { local, dev, test, prod }

extension ReleaseTypeX on ReleaseType {
  String get nameStr => name;

  static ReleaseType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'local':
        debugPrint('🌍 Running in: $type');
        return ReleaseType.local;
      case 'dev':
        debugPrint('🌍 Running in: $type');
        return ReleaseType.dev;
      case 'test':
        debugPrint('🌍 Running in: $type');
        return ReleaseType.test;

      case 'prod':
        return ReleaseType.prod;
      default:
        throw Exception("Unsupported releaseType: $type");
    }
  }
}

class AppEnvironment {
  static final AppEnvironment _singleton = AppEnvironment._internal();
  factory AppEnvironment() => _singleton;
  AppEnvironment._internal();

  late final ReleaseType releaseType;

  Future<void> init() async {
    releaseType = await _detectReleaseType();
    await _initFirebase();
  }

  Future<ReleaseType> _detectReleaseType() async {
    if (kDebugMode) {
      return ReleaseType.local;
    }

    try {
      final yamlStr = await rootBundle.loadString('pubspec.yaml');
      final yamlMap = loadYaml(yamlStr);
      final typeStr = yamlMap['releaseType'] as String?;
      if (typeStr != null) {
        return ReleaseTypeX.fromString(typeStr);
      }
    } catch (_) {
      // fallback if pubspec can't be read
    }

    return ReleaseType.prod; // fallback
  }

  Future<void> _initFirebase() async {
    final options = switch (releaseType) {
      ReleaseType.local => dev.DefaultFirebaseOptions.currentPlatform,
      ReleaseType.dev => dev.DefaultFirebaseOptions.currentPlatform,
      ReleaseType.test => dev.DefaultFirebaseOptions.currentPlatform,
      ReleaseType.prod => prod.DefaultFirebaseOptions.currentPlatform,
    };

    await Firebase.initializeApp(options: options);
  }
}
