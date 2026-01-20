import 'package:flutter/material.dart';

class QuickRangeSelector extends StatelessWidget {
  const QuickRangeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = ['Today', 'All'];
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final selected = value == option;
        return GestureDetector(
          onTap: () => onChanged(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1B1C20) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? const Color(0xFF1B1C20) : const Color(0xFFDDDFE4),
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1B1C20),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
