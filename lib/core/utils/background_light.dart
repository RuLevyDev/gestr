import 'dart:math';
import 'package:flutter/material.dart';

class BackgroundLight extends StatefulWidget {
  const BackgroundLight({super.key});

  @override
  State<BackgroundLight> createState() => _BackgroundLightState();
}

class _BackgroundLightState extends State<BackgroundLight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Shape> _shapes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _shapes = List.generate(
      10,
      (index) => Shape(
        position: Offset(
          Random().nextDouble() * 500,
          Random().nextDouble() * 800,
        ),
        velocity: Offset(
          (Random().nextDouble() - 0.5) * 1,
          (Random().nextDouble() - 0.5) * 1,
        ),
        size: 1000 + Random().nextInt(200).toDouble(),
        blurRadius: 500 + Random().nextInt(400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var shape in _shapes) {
          shape.updatePosition();
        }

        return Container(
          color: Colors.white,
          child: Stack(
            children:
                _shapes.map((shape) {
                  return Positioned(
                    left: shape.position.dx,
                    top: shape.position.dy,
                    child: AnimatedContainer(
                      duration: Duration.zero,
                      width: shape.size,
                      height: shape.size,
                      decoration: BoxDecoration(
                        color: shape.color.withValues(
                          alpha: (0.01),
                        ), // ligera opacidad blanca
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: shape.color.withValues(
                              alpha: (0.2), // da 26
                            ), // sombra teal más visible
                            blurRadius: shape.blurRadius.toDouble(),
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }
}

class Shape {
  Offset position;
  Offset velocity;
  double size;
  Color color;
  int blurRadius;

  Shape({
    required this.position,
    required this.velocity,
    required this.size,
    required this.blurRadius,
  }) : color = _getRandomColorTeal();

  void updatePosition() {
    position = position + velocity;

    if (position.dx <= 0 || position.dx >= 500) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy <= 0 || position.dy >= 800) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }
  }

  static Color _getRandomColorTeal() {
    final Random random = Random();
    List<Color> colors = [
      Color.fromRGBO(0, 128, 128, 1), // Teal oscuro
      Color.fromRGBO(0, 150, 136, 1), // Teal medio
      Color.fromRGBO(77, 182, 172, 1), // Teal claro
      Color.fromRGBO(128, 224, 208, 1), // Teal pastel
      Color.fromRGBO(0, 105, 92, 1), // Teal profundo
      Color.fromRGBO(38, 198, 218, 1), // Cyan brillante
    ];
    return colors[random.nextInt(colors.length)];
  }
}
