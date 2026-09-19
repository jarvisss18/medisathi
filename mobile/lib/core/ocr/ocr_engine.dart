import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_result.dart';
import 'regex_token_parser.dart';

class OcrEngine {
  TextRecognizer? _textRecognizer;

  OcrEngine() {
    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    } catch (_) {
      _textRecognizer = null;
    }
  }

  /// Processes a single image file path and returns parsed OCR result.
  Future<ParsedOcrResult> processImageFile(String imagePath) async {
    if (_textRecognizer == null) {
      return parseRawText("");
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
      return parseRawText(recognizedText.text);
    } catch (_) {
      return parseRawText("");
    }
  }

  /// Multi-frame voting logic: Combines 3 burst frames and performs voting
  /// on extracted strength, batch, and text tokens to maximize accuracy.
  Future<ParsedOcrResult> processBurstFrames(List<String> framePaths) async {
    if (framePaths.isEmpty) {
      return parseRawText("");
    }

    final List<ParsedOcrResult> frameResults = [];
    for (final path in framePaths) {
      final result = await processImageFile(path);
      frameResults.add(result);
    }

    return performMultiFrameVoting(frameResults);
  }

  /// Multi-frame voting logic over parsed frame results.
  ParsedOcrResult performMultiFrameVoting(List<ParsedOcrResult> frameResults) {
    if (frameResults.isEmpty) {
      return parseRawText("");
    }

    if (frameResults.length == 1) {
      return frameResults.first;
    }

    // 1. Voting on Strength
    final Map<String, int> strengthVotes = {};
    for (final res in frameResults) {
      if (res.extractedStrength != null) {
        strengthVotes[res.extractedStrength!] = (strengthVotes[res.extractedStrength!] ?? 0) + 1;
      }
    }

    String? votedStrength;
    if (strengthVotes.isNotEmpty) {
      votedStrength = strengthVotes.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    // 2. Voting on Batch
    final Map<String, int> batchVotes = {};
    for (final res in frameResults) {
      if (res.extractedBatch != null) {
        batchVotes[res.extractedBatch!] = (batchVotes[res.extractedBatch!] ?? 0) + 1;
      }
    }

    String? votedBatch;
    if (batchVotes.isNotEmpty) {
      votedBatch = batchVotes.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    // 3. Combine raw text and tokens
    final combinedRawText = frameResults.map((r) => r.rawText).join("\n");
    final Set<String> tokenSet = {};
    for (final res in frameResults) {
      tokenSet.addAll(res.tokens);
    }

    final expiry = frameResults.firstWhere((r) => r.extractedExpiry != null, orElse: () => frameResults.first).extractedExpiry;

    return ParsedOcrResult(
      rawText: combinedRawText,
      tokens: tokenSet.toList(),
      extractedStrength: votedStrength,
      extractedBatch: votedBatch,
      extractedExpiry: expiry,
      matchedKeywords: tokenSet.toList(),
      confidenceScore: votedStrength != null ? 0.90 : 0.65,
    );
  }

  /// Parses raw text directly using RegexTokenParser.
  ParsedOcrResult parseRawText(String rawText) {
    final tokens = RegexTokenParser.tokenize(rawText);
    final strength = RegexTokenParser.extractStrength(rawText);
    final batch = RegexTokenParser.extractBatch(rawText);
    final expiry = RegexTokenParser.extractExpiry(rawText);

    double score = 0.50;
    if (strength != null) score += 0.30;
    if (batch != null) score += 0.10;
    if (tokens.isNotEmpty) score += 0.10;

    return ParsedOcrResult(
      rawText: rawText,
      tokens: tokens,
      extractedStrength: strength,
      extractedBatch: batch,
      extractedExpiry: expiry,
      matchedKeywords: tokens,
      confidenceScore: score.clamp(0.0, 1.0),
    );
  }

  void close() {
    _textRecognizer?.close();
  }
}
