import 'dart:io';

import 'package:flutter/foundation.dart';

void main() {
  final plistPath = 'ios/Runner/Info.plist';
  final plistFile = File(plistPath);
  if (!plistFile.existsSync()) {
    debugPrint('Error: No se encontró $plistPath');
    exit(1);
  }

  String content = plistFile.readAsStringSync();

  final keysToAdd = {
    'NSPhotoLibraryUsageDescription':
        'Esta app necesita acceso a la biblioteca de fotos para que puedas seleccionar imágenes.',
    'NSCameraUsageDescription':
        'Esta app necesita acceso a la cámara para poder tomar fotos y videos.',
    'NSMicrophoneUsageDescription':
        'Esta app necesita acceso al micrófono para grabar audio en los videos.',
  };

  for (final key in keysToAdd.keys) {
    final keyPattern = RegExp(
      '<key>$key</key>\\s*<string>.*?</string>',
      dotAll: true,
    );
    final newEntry = '<key>$key</key>\n<string>${keysToAdd[key]}</string>';

    if (keyPattern.hasMatch(content)) {
      // Reemplaza el contenido si ya existe
      content = content.replaceAll(keyPattern, newEntry);
      debugPrint('Actualizado permiso para $key');
    } else {
      // Inserta antes del cierre de dict
      final insertPos = content.lastIndexOf('</dict>');
      if (insertPos != -1) {
        content =
            '${content.substring(0, insertPos)}\n  $newEntry\n${content.substring(insertPos)}';
        debugPrint('Agregado permiso para $key');
      }
    }
  }

  plistFile.writeAsStringSync(content);
  debugPrint('Archivo Info.plist actualizado correctamente.');
}
