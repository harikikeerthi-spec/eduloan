import 'package:flutter/material.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final TextInputType keyboardType;
  final bool isNumber;
  final int maxLines;
  final TextStyle? style;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.keyboardType = TextInputType.text,
    this.isNumber = false,
    this.maxLines = 1,
    this.style,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: style,
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
