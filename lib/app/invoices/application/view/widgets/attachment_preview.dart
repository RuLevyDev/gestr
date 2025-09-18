import 'dart:io';
import 'package:flutter/material.dart';

class AttachmentPreview extends StatelessWidget {
  const AttachmentPreview({
    super.key,
    required this.file,
    required this.onRemove,
  });

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Image.file(file, height: 150),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRemove,
          icon: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.onSurface,
          ),
          label: const Text('Eliminar imagen'),
        ),
      ],
    );
  }
}

