// Página para rutas no encontradas (opcional)
import 'package:flutter/material.dart';
import 'package:gestr/core/utils/app_strings.dart';

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Strings.instance.unknownRouteTitle)),
      body: Center(
        child: Text(
          Strings.instance.unknownRouteBody,
          style: TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
