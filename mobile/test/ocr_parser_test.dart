import 'package:flutter_test/flutter_test.dart';
import 'package:medisathi/core/ocr/regex_token_parser.dart';
import 'package:medisathi/core/ocr/ocr_engine.dart';

void main() {
  group('RegexTokenParser Tests', () {
    test('Extracts strength correctly from various formats', () {
      expect(RegexTokenParser.extractStrength('Paracetamol Tablets IP 500 mg'), '500 mg');
      expect(RegexTokenParser.extractStrength('Amlodipine 5mg'), '5 mg');
      expect(RegexTokenParser.extractStrength('Atorvastatin 10 MG'), '10 mg');
      expect(RegexTokenParser.extractStrength('No strength here'), null);
    });

    test('Extracts batch number correctly', () {
      expect(RegexTokenParser.extractBatch('Batch: B1234\nExp: 12/2027'), 'B1234');
      expect(RegexTokenParser.extractBatch('B.No. LOT-99812'), 'LOT-99812');
      expect(RegexTokenParser.extractBatch('Plain text without batch'), null);
    });

    test('Extracts expiry date correctly', () {
      expect(RegexTokenParser.extractExpiry('Exp: 12/2027'), '12/2027');
      expect(RegexTokenParser.extractExpiry('EXP: 05-2026'), '05-2026');
      expect(RegexTokenParser.extractExpiry('No expiry info'), null);
    });

    test('Tokenizes raw text into normalized lowercase tokens', () {
      final tokens = RegexTokenParser.tokenize('Paracetamol 500 mg Tablets IP');
      expect(tokens, containsAll(['paracetamol', '500', 'mg', 'tablets', 'ip']));
    });
  });

  group('OcrEngine Multi-Frame Voting Tests', () {
    late OcrEngine engine;

    setUp(() {
      engine = OcrEngine();
    });

    test('Single frame parsing extracts strength and tokens', () {
      final result = engine.parseRawText('Paracetamol 500 mg\nBatch: B9901');
      expect(result.extractedStrength, '500 mg');
      expect(result.extractedBatch, 'B9901');
      expect(result.tokens, contains('paracetamol'));
    });

    test('Multi-frame voting resolves majority strength across 3 frames', () {
      final frame1 = engine.parseRawText('Paraceta... 500 mg');
      final frame2 = engine.parseRawText('Paracetamol 500 mg');
      final frame3 = engine.parseRawText('Paracetamol 650 mg'); // Outlier frame

      final votedResult = engine.performMultiFrameVoting([frame1, frame2, frame3]);

      // Majority vote wins: 500 mg (2 votes) vs 650 mg (1 vote)
      expect(votedResult.extractedStrength, '500 mg');
      expect(votedResult.tokens, contains('paracetamol'));
    });
  });
}
