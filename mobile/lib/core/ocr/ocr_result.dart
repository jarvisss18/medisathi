class ParsedOcrResult {
  final String rawText;
  final List<String> tokens;
  final String? extractedStrength;
  final String? extractedBatch;
  final String? extractedExpiry;
  final List<String> matchedKeywords;
  final double confidenceScore;

  ParsedOcrResult({
    required this.rawText,
    required this.tokens,
    this.extractedStrength,
    this.extractedBatch,
    this.extractedExpiry,
    required this.matchedKeywords,
    required this.confidenceScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'rawText': rawText,
      'tokens': tokens,
      'extractedStrength': extractedStrength,
      'extractedBatch': extractedBatch,
      'extractedExpiry': extractedExpiry,
      'matchedKeywords': matchedKeywords,
      'confidenceScore': confidenceScore,
    };
  }
}
