import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
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

    // Load canonical medicines dataset from root data directory or assets
    final medicinesFile = File('../data/medicines.json');
    if (medicinesFile.existsSync()) {
      final jsonStr = medicinesFile.readAsStringSync();
      catalog = List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
    } else {
      // Fallback mock catalog for testing environment
      catalog = [
        {
          "medicine_id": "MED-001",
          "canonical_name": "Paracetamol",
          "brand_name": "Crocin",
          "aliases": ["paracetamol", "acetaminophen"],
          "strength": "500 mg",
          "ocr_keywords": ["paracetamol", "500", "mg"],
          "lookalike_group_id": "LA-PARA",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-003",
          "canonical_name": "Amlodipine",
          "brand_name": "Amlokind",
          "aliases": ["amlodipine"],
          "strength": "5 mg",
          "ocr_keywords": ["amlodipine", "5", "mg"],
          "lookalike_group_id": "LA-AMLO",
          "color_signature": {"calibrated": false},
        },
        {
          "medicine_id": "MED-004",
          "canonical_name": "Amlodipine",
          "brand_name": "Amlokind",
          "aliases": ["amlodipine"],
          "strength": "10 mg",
          "ocr_keywords": ["amlodipine", "10", "mg"],
          "lookalike_group_id": "LA-AMLO",
          "color_signature": {"calibrated": false},
        },
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
      expect(decision.matchedMedicineId, 'MED-001');
      expect(decision.confidenceScore, greaterThanOrEqualTo(0.85));
    });

    test('TEST-002: Quality Check Failure forces REVIEW state (Don\'t Guess)', () {
      final ocrResult = ocrEngine.parseRawText("Paracetamol 500 mg");
      final failedQuality = QualityCheckResult(
        laplacianVariance: 45.0, // Failed blur threshold
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
      // Amlodipine without 5mg or 10mg specified
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
  });
}
