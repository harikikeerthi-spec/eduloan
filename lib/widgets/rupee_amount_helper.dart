import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Formatter that automatically inserts Indian currency commas (e.g. 2,50,00,00,00,000)
class IndianCurrencyFormatter extends TextInputFormatter {
  final double? maxAmount;
  final int? maxDigits;

  IndianCurrencyFormatter({this.maxAmount, this.maxDigits});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) return newValue.copyWith(text: '');

    if (maxDigits != null && text.length > maxDigits!) {
      text = text.substring(0, maxDigits!);
    }

    if (maxAmount != null) {
      final parsed = double.tryParse(text);
      if (parsed != null && parsed > maxAmount!) {
        text = maxAmount!.toInt().toString();
      }
    }

    String formatted = formatIndianCurrency(text);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String formatIndianCurrency(String text) {
    if (text.length <= 3) return text;

    String lastThree = text.substring(text.length - 3);
    String remaining = text.substring(0, text.length - 3);

    String groupedRemaining = "";
    int count = 0;
    for (int i = remaining.length - 1; i >= 0; i--) {
      groupedRemaining = remaining[i] + groupedRemaining;
      count++;
      if (count == 2 && i > 0) {
        groupedRemaining = ",$groupedRemaining";
        count = 0;
      }
    }

    return "$groupedRemaining,$lastThree";
  }
}

/// Helper function that converts numeric text into formatted Rupee text + Lakhs/Crores display
String getRupeeAmountHelperText(String val, {String label = 'Amount'}) {
  final cleanStr = val.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleanStr.isEmpty) return '';

  final amount = double.tryParse(cleanStr) ?? 0;
  if (amount <= 0) return '';

  final formattedRupees = IndianCurrencyFormatter.formatIndianCurrency(cleanStr);
  final lakhs = amount / 100000;
  final crores = amount / 10000000;

  if (crores >= 1.0) {
    return '$label: ₹$formattedRupees (${lakhs.toStringAsFixed(2)} Lakhs)';
  } else if (lakhs >= 1.0) {
    return '$label: ₹$formattedRupees (${lakhs.toStringAsFixed(2)} Lakhs)';
  } else {
    return '$label: ₹$formattedRupees';
  }
}

/// Reusable helper card widget displayed under any amount field in the app
class RupeeAmountHelperCard extends StatelessWidget {
  final String amountText;
  final String label;

  const RupeeAmountHelperCard({
    super.key,
    required this.amountText,
    this.label = 'Amount',
  });

  @override
  Widget build(BuildContext context) {
    final helperText = getRupeeAmountHelperText(amountText, label: label);
    if (helperText.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF311B92).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF311B92).withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF311B92)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              helperText,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF311B92),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
