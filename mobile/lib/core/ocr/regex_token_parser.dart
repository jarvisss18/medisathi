class RegexTokenParser {
  static final RegExp _strengthRegex = RegExp(
    r'(\d+(?:\.\d+)?)\s*(mg|g|mcg|ml|iu|%)\b',
    caseSensitive: false,
  );

  static final RegExp _batchRegex = RegExp(
    r'(?:B\.?\s*No\.?|Batch|B\/N|Lot|Btch)\s*[:\.\-]?\s*([A-Z0-9\-]{3,15})',
    caseSensitive: false,
  );

  static final RegExp _expiryRegex = RegExp(
    r'(?:Exp|Expiry|EXP)\s*[:\.\-]?\s*(\d{2}[\/\-]\d{2,4}|\w{3}\s*\d{2,4})',
    caseSensitive: false,
  );

  /// Extracts strength (e.g. "500 mg", "5 mg", "10 mg") from text.
  static String? extractStrength(String text) {
    final match = _strengthRegex.firstMatch(text);
    if (match != null) {
      final value = match.group(1);
      final unit = match.group(2)?.toLowerCase();
      return '$value $unit';
    }
    return null;
  }

  /// Extracts batch number (e.g. "B1234", "LOT-998") from text.
  static String? extractBatch(String text) {
    final match = _batchRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }

  /// Extracts expiry date (e.g. "12/2027", "EXP: 05/26") from text.
  static String? extractExpiry(String text) {
    final match = _expiryRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)?.trim();
    }
    return null;
  }

  /// Tokenizes raw OCR text into normalized lowercase alphanumeric tokens.
  static List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && t.length > 1)
        .toList();
  }
}
