import 'dart:math';
import 'package:flutter/material.dart';

class DialogBackground extends StatefulWidget {
  const DialogBackground({super.key});

  @override
  State<DialogBackground> createState() => _DialogBackgroundState();
}

class _DialogBackgroundState extends State<DialogBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Shape> _shapes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
        seconds: 15,
      ), // Aumentar duración para un movimiento más suave
      vsync: this,
    )..repeat();

    _shapes = List.generate(
      10, // Aumentar número de objetos para mayor difuminado
      (index) => Shape(
        position: Offset(
          Random().nextDouble() * 500,
          Random().nextDouble() * 800,
        ),
        velocity: Offset(
          (Random().nextDouble() - 0.5) *
              1, // Menor velocidad para suavizar el movimiento
          (Random().nextDouble() - 0.5) * 1,
        ),
        size: 1000 + Random().nextInt(200).toDouble(), // Tamaños grandes
        blurRadius: 500 + Random().nextInt(400), // Difuminado más grande
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
        // Actualizamos las posiciones de las formas
        for (var shape in _shapes) {
          shape.updatePosition();
        }

        return Container(
          color: Colors.black,
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
                          alpha: 0.01,
                        ), // Menor opacidad
                        shape: BoxShape.circle, // Solo círculos difusos
                        boxShadow: [
                          BoxShadow(
                            color: shape.color.withValues(
                              alpha: 0.05,
                            ), // Baja opacidad
                            blurRadius: shape.blurRadius.toDouble(),
                            spreadRadius:
                                10, // Reducir spread para sombras suaves
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
  }) : color = _getRandomColorPurple();

  void updatePosition() {
    position = position + velocity;

    // Rebotar en los bordes
    if (position.dx <= 0 || position.dx >= 500) {
      velocity = Offset(-velocity.dx, velocity.dy);
    }
    if (position.dy <= 0 || position.dy >= 800) {
      velocity = Offset(velocity.dx, -velocity.dy);
    }
  }

  // static Color _getRandomColor() {
  //   final Random random = Random();
  //   List<Color> colors = [
  //     Color.fromRGBO(105, 105, 105, 1), // Gris oscuro
  //     Color.fromRGBO(169, 169, 169, 1), // Gris
  //     Color.fromRGBO(112, 128, 144, 1), // Gris azulado
  //     Color.fromRGBO(70, 130, 180, 1), // Azul acero
  //     Color.fromRGBO(0, 0, 0, 1), // Negro
  //     Color.fromRGBO(169, 169, 169, 1), // Gris claro
  //   ];
  //   return colors[random.nextInt(colors.length)];
  // }

  static Color _getRandomColorPurple() {
    final Random random = Random();
    List<Color> colors = [
      Color.fromRGBO(128, 0, 128, 1), // Púrpura
      Color.fromRGBO(186, 85, 211, 1), // Púrpura medio
      Color.fromRGBO(147, 112, 219, 1), // Lavanda
      Color.fromRGBO(138, 43, 226, 1), // Azul violeta
      Color.fromRGBO(75, 0, 130, 1), // Índigo
      Color.fromRGBO(219, 112, 147, 1), // Púrpura rosado
    ];
    return colors[random.nextInt(colors.length)];
  }
}
