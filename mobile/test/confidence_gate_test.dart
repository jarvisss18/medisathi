import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisathi/core/csv/csv_parser.dart';
import 'package:medisathi/core/gate/confidence_gate.dart';
import 'package:medisathi/core/ocr/ocr_engine.dart';
import 'package:medisathi/core/quality/quality_checker.dart';

void main() {
  late ConfidenceGate gate;
  late OcrEngine ocrEngine;
  late List<Map<String, dynamic>> catalog;

  setUp(() {
    gate = ConfidenceGate(matchAcceptMin: 0.85, reviewMin: 0.60);
    ocrEngine = OcrEngine();

    final csvFile = File('../data/medicines.csv');
    if (csvFile.existsSync()) {
      catalog = CsvParser.parseMedicineCatalogCsv(csvFile.readAsStringSync());
    } else {
      catalog = [
        {
          "medicine_id": "MED-001",
          "canonical_name": "Paracetamol",
          "brand_name": "Crocin 500",
          "aliases": ["paracetamol", "crocin"],
          "strength": "500 mg",
          "ocr_keywords": ["paracetamol", "500", "mg"],
          "lookalike_group_id": "LA-PARA",
        },
        {
          "medicine_id": "MED-003",
          "canonical_name": "Amlodipine",
          "brand_name": "Amlokind 5",
          "aliases": ["amlodipine", "amlokind"],
          "strength": "5 mg",
          "ocr_keywords": ["amlodipine", "5", "mg"],
          "lookalike_group_id": "LA-AMLO",
        },
        {
          "medicine_id": "MED-011",
          "canonical_name": "Pantoprazole",
          "brand_name": "Pan 40",
          "aliases": ["pantoprazole", "pan 40", "pan"],
          "strength": "40 mg",
          "ocr_keywords": ["pantoprazole", "40", "mg", "pan"],
        }
      ];
    }
  });

  group('ConfidenceGate Safety Rule Tests', () {
    test('TEST-001: Clear Paracetamol 500 mg image produces MATCH decision', () {
      final ocrResult = ocrEngine.parseRawText("Paracetamol Tablets IP 500 mg\nBatch: B1234");
      final qualityResult = QualityCheckResult(
        laplacianVariance: 180.0,
        glareRatio: 0.02,
        meanBrightness: 128.0,
        isBlurPassed: true,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: true,
      );

      final decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: qualityResult,
        medicinesCatalog: catalog,
      );

      expect(decision.state, GateDecisionState.match);
      expect(decision.matchedCanonicalName, 'Paracetamol');
      expect(decision.confidenceScore, greaterThanOrEqualTo(0.85));
    });

    test('TEST-002: Quality Check Failure forces REVIEW state (Don\'t Guess)', () {
      final ocrResult = ocrEngine.parseRawText("Paracetamol 500 mg");
      final failedQuality = QualityCheckResult(
        laplacianVariance: 45.0,
        glareRatio: 0.05,
        meanBrightness: 110.0,
        isBlurPassed: false,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: false,
        failureReason: "QUALITY_BLUR_FAILED",
      );

      final decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: failedQuality,
        medicinesCatalog: catalog,
      );

      expect(decision.state, GateDecisionState.review);
      expect(decision.reasonCode, contains('QUALITY_BLUR_FAILED'));
    });

    test('TEST-003: Look-alike medicine with missing strength forces REVIEW', () {
      final ocrResult = ocrEngine.parseRawText("Amlodipine Tablets IP");
      final qualityResult = QualityCheckResult(
        laplacianVariance: 150.0,
        glareRatio: 0.01,
        meanBrightness: 130.0,
        isBlurPassed: true,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: true,
      );

      final decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: qualityResult,
        medicinesCatalog: catalog,
      );

      expect(decision.state, GateDecisionState.review);
      expect(decision.reasonCode, equals('LOOKALIKE_AMBIGUITY_STRENGTH_MISSING'));
    });

    test('TEST-004: Unrecognized non-medicine text produces REJECT state', () {
      final ocrResult = ocrEngine.parseRawText("Random Vitamin Compound XYZ 1000 IU");
      final qualityResult = QualityCheckResult(
        laplacianVariance: 200.0,
        glareRatio: 0.01,
        meanBrightness: 140.0,
        isBlurPassed: true,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: true,
      );

      final decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: qualityResult,
        medicinesCatalog: catalog,
      );

      expect(decision.state, GateDecisionState.reject);
      expect(decision.reasonCode, equals('NO_MATCH_FOUND'));
    });

    test('TEST-005: Low strength 5mg medicine (Amlodipine 5mg) matches correctly', () {
      final ocrResult = ocrEngine.parseRawText("Amlokind 5 mg Tablets");
      final qualityResult = QualityCheckResult(
        laplacianVariance: 180.0,
        glareRatio: 0.01,
        meanBrightness: 130.0,
        isBlurPassed: true,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: true,
      );

      final decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: qualityResult,
        medicinesCatalog: catalog,
      );

      expect(decision.state, GateDecisionState.match);
      expect(decision.matchedCanonicalName, 'Amlodipine');
      expect(decision.matchedStrength, '5 mg');
    });

    test('TEST-006: Brand alias Pan 40 (Pantoprazole 40 mg) matches correctly', () {
      final ocrResult = ocrEngine.parseRawText("Pan 40 Gastro-resistant Tablets");
      final qualityResult = QualityCheckResult(
        laplacianVariance: 180.0,
        glareRatio: 0.01,
        meanBrightness: 130.0,
        isBlurPassed: true,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: true,
      );

      final decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: qualityResult,
        medicinesCatalog: catalog,
      );

      expect(decision.state, GateDecisionState.match);
      expect(decision.matchedCanonicalName, 'Pantoprazole');
      expect(decision.matchedStrength, '40 mg');
    });
  });
}
