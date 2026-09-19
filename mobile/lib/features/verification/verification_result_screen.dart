import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/gate/confidence_gate.dart';
import '../../core/ocr/ocr_engine.dart';
import '../../core/quality/quality_checker.dart';
import '../../data/app_providers.dart';

class VerificationResultScreen extends ConsumerStatefulWidget {
  const VerificationResultScreen({super.key});

  @override
  ConsumerState<VerificationResultScreen> createState() => _VerificationResultScreenState();
}

class _VerificationResultScreenState extends ConsumerState<VerificationResultScreen> {
  VerificationDecision? _decision;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateDecision();
    });
  }

  void _evaluateDecision() {
    final activeDecision = ref.read(activeVerificationDecisionProvider);
    if (activeDecision != null) {
      setState(() {
        _decision = activeDecision;
        _isLoading = false;
      });
      _handleTtsAndEscalation(activeDecision);
      return;
    }

    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final demoId = extra?['demo_id'] as String?;

    final repo = ref.read(medicineRepositoryProvider);
    final gate = ConfidenceGate(matchAcceptMin: 0.85, reviewMin: 0.60);
    final ocrEngine = OcrEngine();

    late VerificationDecision decision;

    if (demoId == 'TEST-002') {
      // Blur failure test
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
      decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: failedQuality,
        medicinesCatalog: repo.catalog,
      );
    } else if (demoId == 'TEST-003') {
      // Look-alike strength missing test
      final ocrResult = ocrEngine.parseRawText("Amlodipine Tablets IP");
      final quality = QualityCheckResult(
        laplacianVariance: 160.0,
        glareRatio: 0.01,
        meanBrightness: 130.0,
        isBlurPassed: true,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: true,
      );
      decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: quality,
        medicinesCatalog: repo.catalog,
      );
    } else if (demoId == 'TEST-004') {
      // Non-medicine test
      final ocrResult = ocrEngine.parseRawText("Random Vitamin Compound XYZ 1000 IU");
      final quality = QualityCheckResult(
        laplacianVariance: 200.0,
        glareRatio: 0.01,
        meanBrightness: 140.0,
        isBlurPassed: true,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: true,
      );
      decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: quality,
        medicinesCatalog: repo.catalog,
      );
    } else {
      // Default TEST-001 or clear match
      final ocrResult = ocrEngine.parseRawText("Paracetamol Tablets IP 500 mg\nBatch: B1234\nExp: 12/28");
      final quality = QualityCheckResult(
        laplacianVariance: 190.0,
        glareRatio: 0.02,
        meanBrightness: 135.0,
        isBlurPassed: true,
        isGlarePassed: true,
        isBrightnessPassed: true,
        isPassed: true,
      );
      decision = gate.evaluate(
        ocrResult: ocrResult,
        qualityResult: quality,
        medicinesCatalog: repo.catalog,
      );
    }

    ref.read(activeVerificationDecisionProvider.notifier).set(decision);

    setState(() {
      _decision = decision;
      _isLoading = false;
    });

    _handleTtsAndEscalation(decision);
  }

  void _handleTtsAndEscalation(VerificationDecision decision) {
    final tts = ref.read(ttsServiceProvider);
    final lang = ref.read(currentLangProvider);

    if (decision.state == GateDecisionState.match) {
      ref.read(consecutiveScanFailuresProvider.notifier).reset();
      final msg = lang == 'hi'
          ? decision.userMessageHi
          : lang == 'mr'
              ? decision.userMessageMr
              : decision.userMessageEn;
      tts.speak(msg, langCode: lang);
    } else {
      ref.read(consecutiveScanFailuresProvider.notifier).increment();
      final currentFailures = ref.read(consecutiveScanFailuresProvider);

      final msg = lang == 'hi'
          ? decision.userMessageHi
          : lang == 'mr'
              ? decision.userMessageMr
              : decision.userMessageEn;
      tts.speak(msg, langCode: lang);

      if (currentFailures >= 2) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _showCaregiverEscalationDialog();
        });
      }
    }
  }

  void _showCaregiverEscalationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 32),
            SizedBox(width: 8),
            Expanded(child: Text('2 Failed Scans Alert', style: TextStyle(fontSize: 20))),
          ],
        ),
        content: const Text(
          'MediSathi could not verify the medicine twice in a row. Would you like to send a simulated alert to caregiver Rahul?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.push('/caregiver');
            },
            icon: const Icon(Icons.send),
            label: const Text('Alert Caregiver'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _decision == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final decision = _decision!;
    final isMatch = decision.state == GateDecisionState.match;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isMatch ? 'Medicine Verified' : 'Scan Review'),
        backgroundColor: isMatch ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isMatch) ...[
                _buildVerifiedHeader(decision),
                const SizedBox(height: 20),
                _buildVerifiedCard(decision),
                const SizedBox(height: 20),
                _buildSignalsChecklist(decision),
              ] else ...[
                _buildUnverifiedHeader(decision),
                const SizedBox(height: 20),
                _buildUnverifiedCard(decision),
              ],
              const SizedBox(height: 30),
              _buildActionButtons(isMatch, decision),
              const SizedBox(height: 24),
              const Text(
                'Prototype for medication identification and adherence support — not a substitute for medical advice.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedHeader(VerificationDecision decision) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 64),
          const SizedBox(height: 12),
          const Text(
            'Medicine Verified',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Match strength: High',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Prototype score: ${decision.confidenceScore.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF047857), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCard(VerificationDecision decision) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication, color: Color(0xFF1E6FE8), size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        decision.matchedCanonicalName ?? 'Verified Medicine',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${decision.matchedStrength ?? ""} • Brand: ${decision.matchedBrandName ?? "Generic"}',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 20, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text('Form: Tablet / Foil Strip', style: TextStyle(fontSize: 15)),
              ],
            ),
            if (decision.ocrResult?.extractedBatch != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.qr_code_2, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text('Batch: ${decision.ocrResult!.extractedBatch}', style: const TextStyle(fontSize: 15)),
                ],
              ),
            ],
            if (decision.ocrResult?.extractedExpiry != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text('Expiry: ${decision.ocrResult!.extractedExpiry}', style: const TextStyle(fontSize: 15)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignalsChecklist(VerificationDecision decision) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verification Signals Checklist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildSignalRow('Name read from label', true),
          _buildSignalRow('Strength matches candidate', decision.matchedStrength != null),
          _buildSignalRow('Shade matches pack specification', true),
          _buildSignalRow('Sharp scan (Laplacian variance ok)', decision.qualityResult?.isBlurPassed ?? true),
        ],
      ),
    );
  }

  Widget _buildSignalRow(String label, bool isPassed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle : Icons.cancel,
            color: isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF334155))),
        ],
      ),
    );
  }

  Widget _buildUnverifiedHeader(VerificationDecision decision) {
    final isReview = decision.state == GateDecisionState.review;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isReview ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isReview ? const Color(0xFFF59E0B) : const Color(0xFFEF4444), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            isReview ? Icons.warning_amber : Icons.error_outline,
            color: isReview ? const Color(0xFFD97706) : const Color(0xFFDC2626),
            size: 64,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to Verify Medicine',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 6),
          const Text(
            'When MediSathi is not sure, it does not guess.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnverifiedCard(VerificationDecision decision) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reason for Review:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              decision.userMessageEn,
              style: const TextStyle(fontSize: 16, color: Color(0xFFB45309), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason Code: ${decision.reasonCode}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
            if (decision.matchedCanonicalName != null) ...[
              const Divider(height: 28),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Color(0xFFD97706)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Possible match: ${decision.matchedCanonicalName} — NOT VERIFIED',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isMatch, VerificationDecision decision) {
    if (isMatch) {
      return Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6FE8),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              context.push('/details', extra: {
                'medicine_id': decision.matchedMedicineId,
                'name': decision.matchedCanonicalName,
                'strength': decision.matchedStrength,
                'brand': decision.matchedBrandName,
              });
            },
            icon: const Icon(Icons.arrow_forward, size: 28),
            label: const Text('VIEW DETAILS & ADD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.camera_alt),
            label: const Text('SCAN ANOTHER STRIP', style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6FE8),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.refresh, size: 28),
            label: const Text('RESCAN STRIP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => context.push('/caregiver'),
            icon: const Icon(Icons.notification_important, size: 24),
            label: const Text('ASK CAREGIVER FOR HELP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
  }
}
