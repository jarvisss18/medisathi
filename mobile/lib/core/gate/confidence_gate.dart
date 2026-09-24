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
      final brand = (med['brand_name'] as String? ?? '').toLowerCase();
      final aliases = (med['aliases'] as List?)
              ?.map((a) => a.toString().toLowerCase())
              .toList() ??
          [];
      final ocrKeywords = (med['ocr_keywords'] as List?)
              ?.map((k) => k.toString().toLowerCase())
              .toList() ??
          [];
      final strength = (med['strength'] as String).toLowerCase();

      final rawTextLower = ocrResult.rawText.toLowerCase();

      // ── Name matching (canonical name, brand name, aliases, OCR keywords) ──
      bool nameMatched = false;
      double nameScore = 0.0;

      // 1. Full canonical name or brand name present in raw text
      if (rawTextLower.contains(canonical) || (brand.isNotEmpty && rawTextLower.contains(brand))) {
        nameMatched = true;
        nameScore = 1.0;
      } else {
        // 2. Any alias present in raw text (e.g. brand name, INN variant)
        for (final alias in aliases) {
          if (alias.isNotEmpty && rawTextLower.contains(alias)) {
            nameMatched = true;
            nameScore = 0.95;
            break;
          }
        }
      }

      // 3. OCR keywords matching
      if (!nameMatched) {
        for (final kw in ocrKeywords) {
          if (kw.length >= 3 && rawTextLower.contains(kw)) {
            nameMatched = true;
            nameScore = 0.85;
            break;
          }
        }
      }

      // 4. Token-level partial match (tokens >= 3 chars)
      if (!nameMatched) {
        for (final token in ocrResult.tokens) {
          final t = token.toLowerCase();
          if (t.length >= 3) {
            if (canonical.contains(t) || t.contains(canonical) || (brand.isNotEmpty && (brand.contains(t) || t.contains(brand)))) {
              nameMatched = true;
              nameScore = 0.75;
              break;
            }
            for (final alias in aliases) {
              if (alias.length >= 3 && (alias.contains(t) || t.contains(alias))) {
                nameMatched = true;
                nameScore = 0.70;
                break;
              }
            }
          }
          if (nameMatched) break;
        }
      }

      // 5. Fuzzy Levenshtein matching for OCR typos
      if (!nameMatched) {
        for (final token in ocrResult.tokens) {
          final t = token.toLowerCase();
          if (t.length >= 4) {
            if (_similarityScore(t, canonical) >= 0.75 || (brand.isNotEmpty && _similarityScore(t, brand) >= 0.75)) {
              nameMatched = true;
              nameScore = 0.80;
              break;
            }
            for (final alias in aliases) {
              if (alias.length >= 4 && _similarityScore(t, alias) >= 0.75) {
                nameMatched = true;
                nameScore = 0.75;
                break;
              }
            }
          }
          if (nameMatched) break;
        }
      }

      if (!nameMatched) continue;

      // ── Strength matching (universal for 1mg, 2mg, 5mg, 10mg, 20mg, 40mg, 50mg, 75mg, 150mg, 400mg, 500mg, 650mg, 850mg) ──
      final strengthDigits = strength.replaceAll(RegExp(r'[^0-9]'), '');
      final compactStrength = strength.replaceAll(' ', '');
      final compactRaw = rawTextLower.replaceAll(' ', '');

      bool strengthMatched = false;
      double strScore = 0.0;

      // 1. Exact strength string in raw text (e.g. "5 mg" or "5mg" or "10 mg")
      if (rawTextLower.contains(strength) || compactRaw.contains(compactStrength)) {
        strengthMatched = true;
        strScore = 0.30;
      }
      // 2. Extracted strength from OCR parser matches
      else if (ocrResult.extractedStrength != null) {
        final extractedDigits = ocrResult.extractedStrength!.replaceAll(RegExp(r'[^0-9]'), '');
        if (extractedDigits == strengthDigits) {
          strengthMatched = true;
          strScore = 0.25;
        }
      }
      // 3. Digit match with unit or boundary check in raw text
      else if (strengthDigits.isNotEmpty) {
        final regexPattern = RegExp(r'(?:^|\b|_|\s)' + RegExp.escape(strengthDigits) + r'(?:\s*mg|\s*g|\s*mcg|\b|\s)', caseSensitive: false);
        if (regexPattern.hasMatch(rawTextLower) || compactRaw.contains('${strengthDigits}mg')) {
          strengthMatched = true;
          strScore = 0.20;
        }
      }

      // Total score: name quality + strength bonus
      // A name-only match scores min 0.75 (or 0.80/0.95/1.0).
      // A name+strength match adds 0.20-0.30 -> verified match
      final totalScore = nameScore + strScore;

      if (totalScore > maxMatchScore) {
        maxMatchScore = totalScore;
        bestCandidate = med;
        hasStrengthMatch = strengthMatched;
      }
    }

    maxMatchScore = maxMatchScore.clamp(0.0, 1.0);

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
    // Only force review if multiple candidates exist in the catalog for the same lookalike group
    if (lookalikeGroupId != null && !hasStrengthMatch) {
      final candidatesInGroup = medicinesCatalog
          .where((m) => m['lookalike_group_id'] == lookalikeGroupId)
          .map((m) => "${m['canonical_name']} ${m['strength']}")
          .toList();

      if (candidatesInGroup.length > 1) {
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

  double _similarityScore(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    final dist = _editDistance(s1, s2);
    final maxLen = s1.length > s2.length ? s1.length : s2.length;
    return 1.0 - (dist / maxLen);
  }

  int _editDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }
}
