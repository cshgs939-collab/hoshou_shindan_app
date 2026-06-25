import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NumberInputField extends StatelessWidget {
  const NumberInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix = '万円',
    this.hint,
    this.helper,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String suffix;
  final String? hint;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
          controller: TextEditingController(
            text: value != null && value! > 0 ? '$value' : '',
          )..selection = TextSelection.collapsed(
              offset: value != null && value! > 0 ? '$value'.length : 0,
            ),
          onChanged: (text) {
            if (text.isEmpty) {
              onChanged(null);
              return;
            }
            onChanged(int.tryParse(text));
          },
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
