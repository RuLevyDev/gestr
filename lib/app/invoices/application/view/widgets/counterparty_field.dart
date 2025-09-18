import 'package:flutter/material.dart';

class CounterpartyField extends StatelessWidget {
  const CounterpartyField({
    super.key,
    required this.label,
    required this.controller,
    required this.theme,
    required this.onChanged,
    required this.onSubmitted,
    required this.suggestions,
    required this.onTapSuggestion,
  });

  final String label;
  final TextEditingController controller;
  final ThemeData theme;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final List<String> suggestions;
  final void Function(int index) onTapSuggestion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.onSurface),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
        ),
        if (suggestions.isNotEmpty)
          Container(
            height: suggestions.length * 48.0 > 200 ? 200 : suggestions.length * 48.0,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.primary, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < suggestions.length; i++)
                  ListTile(
                    title: Text(suggestions[i]),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    onTap: () => onTapSuggestion(i),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

