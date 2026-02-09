double? parseRupiahInput(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}
