import '../ocr/ocr_result.dart';
import '../quality/quality_checker.dart';
import '../shade/color_extractor.dart';

enum GateDecisionState {
  match, // Verified match (Green)
  review, // Unsure / Needs human review (Amber - "Don't Guess")
  reject, // Unrecognized / No match found (Red)
}

class VerificationDecision {
  final GateDecisionState state;
  final String? matchedMedicineId;
  final String? matchedCanonicalName;
  final String? matchedBrandName;
  final String? matchedStrength;
  final double confidenceScore;
  final String reasonCode;
  final String userMessageEn;
  final String userMessageHi;
  final String userMessageMr;
  final QualityCheckResult? qualityResult;
  final ParsedOcrResult? ocrResult;
  final List<String> lookalikeCandidates;

  VerificationDecision({
    required this.state,
    this.matchedMedicineId,
    this.matchedCanonicalName,
    this.matchedBrandName,
    this.matchedStrength,
    required this.confidenceScore,
    required this.reasonCode,
    required this.userMessageEn,
    required this.userMessageHi,
    required this.userMessageMr,
    this.qualityResult,
    this.ocrResult,
    this.lookalikeCandidates = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'state': state.name.toUpperCase(),
      'matchedMedicineId': matchedMedicineId,
      'matchedCanonicalName': matchedCanonicalName,
      'matchedBrandName': matchedBrandName,
      'matchedStrength': matchedStrength,
      'confidenceScore': confidenceScore,
      'reasonCode': reasonCode,
      'userMessageEn': userMessageEn,
      'userMessageHi': userMessageHi,
      'userMessageMr': userMessageMr,
      'lookalikeCandidates': lookalikeCandidates,
    };
  }
}

class ConfidenceGate {
  final double matchAcceptMin;
  final double reviewMin;

  ConfidenceGate({
    this.matchAcceptMin = 0.85,
    this.reviewMin = 0.60,
  });

  /// Evaluates an OCR result, quality check, color signature against the medicines catalog.
  VerificationDecision evaluate({
    required ParsedOcrResult ocrResult,
    required List<Map<String, dynamic>> medicinesCatalog,
    QualityCheckResult? qualityResult,
    HsvColorSignature? colorSignature,
    bool colorGateEnabled = false,
  }) {
    // Hard Safety Rule A: Quality check failure must lead to REVIEW
    if (qualityResult != null && !qualityResult.isPassed) {
      return VerificationDecision(
        state: GateDecisionState.review,
        confidenceScore: 0.0,
        reasonCode: qualityResult.failureReason ?? "QUALITY_CHECK_FAILED",
        userMessageEn: "Photo is blurry or poorly lit. Please hold steady and try scanning again.",
        userMessageHi: "तस्वीर धुंधली या कम रोशनी वाली है। कृपया हाथ स्थिर रखकर दोबारा स्कैन करें।",
        userMessageMr: "फोटो अस्पष्ट किंवा कमी प्रकाशाचा आहे. कृपया स्थिर धरून पुन्हा स्कॅन करा.",
        qualityResult: qualityResult,
        ocrResult: ocrResult,
      );
    }

    if (ocrResult.tokens.isEmpty) {
      return VerificationDecision(
        state: GateDecisionState.reject,
        confidenceScore: 0.0,
        reasonCode: "NO_TEXT_FOUND",
        userMessageEn: "No text could be read from the strip. Ensure good lighting.",
        userMessageHi: "स्ट्रिप पर कोई पाठ नहीं पढ़ा जा सका। अच्छी रोशनी सुनिश्चित करें।",
        userMessageMr: "पट्टीवर कोणताही मजकूर वाचता आला नाही. चांगला प्रकाश असल्याची खात्री करा.",
        qualityResult: qualityResult,
        ocrResult: ocrResult,
      );
    }

    // Candidate Matching
    Map<String, dynamic>? bestCandidate;
    double maxMatchScore = 0.0;
    bool hasStrengthMatch = false;

    for (final med in medicinesCatalog) {
      final canonical = (med['canonical_name'] as String).toLowerCase();
      final aliases = (med['aliases'] as List).map((a) => a.toString().toLowerCase()).toList();
      final ocrKeywords = (med['ocr_keywords'] as List).map((k) => k.toString().toLowerCase()).toList();
      final strength = (med['strength'] as String).toLowerCase();

      // Check name match
      bool nameMatched = false;
      for (final token in ocrResult.tokens) {
        if (token == canonical || aliases.contains(token) || ocrKeywords.contains(token)) {
          nameMatched = true;
          break;
        }
      }

      if (!nameMatched) continue;

      // Check strength match
      final extractedStrength = ocrResult.extractedStrength?.toLowerCase();
      bool strengthMatched = extractedStrength != null && (extractedStrength == strength || ocrResult.rawText.toLowerCase().contains(strength));

      double nameScore = 0.50;
      double strScore = strengthMatched ? 0.30 : 0.0;
      
      // Color score
      double colorScore = 1.0;
      if (colorGateEnabled && colorSignature != null) {
        colorScore = ColorExtractor.computeColorMatchScore(
          extracted: colorSignature,
          referenceConfig: med['color_signature'],
          gateEnabled: colorGateEnabled,
        );
      }

      double totalScore = nameScore + strScore + (0.20 * colorScore);

      if (totalScore > maxMatchScore) {
        maxMatchScore = totalScore;
        bestCandidate = med;
        hasStrengthMatch = strengthMatched;
      }
    }

    if (bestCandidate == null) {
      return VerificationDecision(
        state: GateDecisionState.reject,
        confidenceScore: 0.20,
        reasonCode: "NO_MATCH_FOUND",
        userMessageEn: "Medicine strip unrecognized. Please verify with caregiver or pharmacist.",
        userMessageHi: "दवा की पट्टी पहचानी नहीं गई। कृपया डॉक्टर या फार्मासिस्ट से जांच करवाएं।",
        userMessageMr: "औषधाची पट्टी ओळखली गेली नाही. कृपया डॉक्टर किंवा फार्मसिस्टकडून तपासा.",
        qualityResult: qualityResult,
        ocrResult: ocrResult,
      );
    }

    final lookalikeGroupId = bestCandidate['lookalike_group_id'];

    // Hard Safety Rule C: Look-alike group + missing strength -> FORCE REVIEW
    if (lookalikeGroupId != null && !hasStrengthMatch) {
      final candidatesInGroup = medicinesCatalog
          .where((m) => m['lookalike_group_id'] == lookalikeGroupId)
          .map((m) => "${m['canonical_name']} ${m['strength']}")
          .toList();

      return VerificationDecision(
        state: GateDecisionState.review,
        matchedMedicineId: bestCandidate['medicine_id'],
        matchedCanonicalName: bestCandidate['canonical_name'],
        matchedBrandName: bestCandidate['brand_name'],
        confidenceScore: maxMatchScore,
        reasonCode: "LOOKALIKE_AMBIGUITY_STRENGTH_MISSING",
        userMessageEn: "Similar medicine detected (${bestCandidate['canonical_name']}), but strength (mg) is unclear. Please check strength carefully.",
        userMessageHi: "समान दवा (${bestCandidate['canonical_name']}) मिली, लेकिन पावर (mg) स्पष्ट नहीं है। कृपया mg ध्यान से देखें।",
        userMessageMr: "सारखे औषध (${bestCandidate['canonical_name']}) आढळले, पण पॉवर (mg) स्पष्ट नाही. कृपया पॉवर काळजीपूर्वक तपासा.",
        qualityResult: qualityResult,
        ocrResult: ocrResult,
        lookalikeCandidates: candidatesInGroup,
      );
    }

    // Hard Safety Rule D: Threshold gate evaluation
    if (maxMatchScore >= matchAcceptMin) {
      return VerificationDecision(
        state: GateDecisionState.match,
        matchedMedicineId: bestCandidate['medicine_id'],
        matchedCanonicalName: bestCandidate['canonical_name'],
        matchedBrandName: bestCandidate['brand_name'],
        matchedStrength: bestCandidate['strength'],
        confidenceScore: maxMatchScore,
        reasonCode: "EXACT_NAME_AND_STRENGTH_MATCH",
        userMessageEn: "Verified: ${bestCandidate['canonical_name']} ${bestCandidate['strength']}.",
        userMessageHi: "सत्यापित: ${bestCandidate['canonical_name']} ${bestCandidate['strength']}।",
        userMessageMr: "सत्यापित: ${bestCandidate['canonical_name']} ${bestCandidate['strength']}.",
        qualityResult: qualityResult,
        ocrResult: ocrResult,
      );
    } else if (maxMatchScore >= reviewMin) {
      return VerificationDecision(
        state: GateDecisionState.review,
        matchedMedicineId: bestCandidate['medicine_id'],
        matchedCanonicalName: bestCandidate['canonical_name'],
        matchedBrandName: bestCandidate['brand_name'],
        confidenceScore: maxMatchScore,
        reasonCode: "LOW_CONFIDENCE_REVIEW",
        userMessageEn: "Partial match for ${bestCandidate['canonical_name']}. Please confirm with the strip label.",
        userMessageHi: "${bestCandidate['canonical_name']} के लिए आंशिक मिलान। कृपया पट्टी के नाम की पुष्टि करें।",
        userMessageMr: "${bestCandidate['canonical_name']} साठी अंशतः जुळणी. कृपया पट्टीवरील नावाची खात्री करा.",
        qualityResult: qualityResult,
        ocrResult: ocrResult,
      );
    } else {
      return VerificationDecision(
        state: GateDecisionState.reject,
        confidenceScore: maxMatchScore,
        reasonCode: "SCORE_BELOW_REJECT_THRESHOLD",
        userMessageEn: "Uncertain match. Please try scanning again with clearer focus.",
        userMessageHi: "अनिश्चित मिलान। कृपया बेहतर रोशनी में दोबारा स्कैन करें।",
        userMessageMr: "अनिश्चित जुळणी. कृपया स्पष्ट प्रकाशात पुन्हा स्कॅन करा.",
        qualityResult: qualityResult,
        ocrResult: ocrResult,
      );
    }
  }
}
