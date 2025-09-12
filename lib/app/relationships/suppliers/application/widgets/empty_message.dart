import 'package:flutter/material.dart';

class EmptyMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyMessage({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);
    return Center(
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
