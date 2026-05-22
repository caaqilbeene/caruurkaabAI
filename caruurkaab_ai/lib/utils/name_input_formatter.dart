import 'package:flutter/services.dart';

String normalizeUserDisplayName(String input) {
  final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.isEmpty) return '';
  return compact.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}

class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  const CapitalizeFirstLetterFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Return newValue directly to prevent keyboard composing region conflicts.
    // The native textCapitalization: TextCapitalization.words handles on-type capitalization,
    // and normalizeUserDisplayName handles normalization on submission.
    return newValue;
  }
}

