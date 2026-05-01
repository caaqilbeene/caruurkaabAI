import 'package:flutter/services.dart';

String _capitalizeFirstNonSpace(String value) {
  if (value.isEmpty) return value;
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char.trim().isEmpty) continue;
    final upper = char.toUpperCase();
    if (upper == char) return value;
    return '${value.substring(0, i)}$upper${value.substring(i + 1)}';
  }
  return value;
}

String normalizeUserDisplayName(String input) {
  final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.isEmpty) return '';
  return _capitalizeFirstNonSpace(compact);
}

class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  const CapitalizeFirstLetterFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final capitalized = _capitalizeFirstNonSpace(newValue.text);
    if (capitalized == newValue.text) return newValue;
    return newValue.copyWith(
      text: capitalized,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
