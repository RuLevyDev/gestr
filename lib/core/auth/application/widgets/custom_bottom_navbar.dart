import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<IconData> icons;
  final List<String> labels;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.icons,
    required this.labels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      // ❌ sin márgenes
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        // ❌ sin borderRadius
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -2), // sombra hacia arriba
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.black.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.6),

              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(icons.length, (index) {
                final isSelected = index == currentIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? (isDark
                                    ? Colors.tealAccent.withValues(alpha: 0.15)
                                    : Colors.purpleAccent.withValues(
                                      alpha: 0.15,
                                    ))
                                : Colors.transparent,

                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: isSelected ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              icons[index],
                              size: 24,
                              color:
                                  isSelected
                                      ? (isDark
                                          ? Colors.tealAccent
                                          : Colors.purpleAccent)
                                      : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w400,
                              color:
                                  isSelected
                                      ? (isDark
                                          ? Colors.tealAccent
                                          : Colors.purpleAccent)
                                      : Colors.grey.shade400,
                            ),
                            child: Text(labels[index]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
