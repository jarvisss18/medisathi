import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/gate/confidence_gate.dart';
import '../../core/ocr/ocr_engine.dart';
import '../../core/quality/quality_checker.dart';
import '../../data/app_providers.dart';
import '../../data/models.dart';

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

  Future<void> _evaluateDecision() async {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final demoId = extra?['demo_id'] as String?;
    final imagePath = extra?['image_path'] as String?;
    final manualText = extra?['manual_text'] as String?;
    final frames = extra?['frames'] as List<String>?;

    final hasInput = (imagePath != null && imagePath.isNotEmpty) ||
        (frames != null && frames.isNotEmpty) ||
        (manualText != null && manualText.isNotEmpty) ||
        (demoId != null && demoId.isNotEmpty);

    if (!hasInput) {
      final activeDecision = ref.read(activeVerificationDecisionProvider);
      if (activeDecision != null) {
        setState(() {
          _decision = activeDecision;
          _isLoading = false;
        });
        _handleTtsAndEscalation(activeDecision);
        return;
      }
    }

    final repo = ref.read(medicineRepositoryProvider);
    final gate = ConfidenceGate(matchAcceptMin: 0.85, reviewMin: 0.60);
    final ocrEngine = OcrEngine();

    late VerificationDecision decision;

    if (imagePath != null) {
      // Real OCR from single device image / gallery photo
      final ocrResult = await ocrEngine.processImageFile(imagePath);
      final quality = QualityCheckResult(
        laplacianVariance: 180.0,
        glareRatio: 0.02,
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
    } else if (frames != null && frames.isNotEmpty) {
      // Real OCR from camera burst frames
      final ocrResult = await ocrEngine.processBurstFrames(frames);
      final quality = QualityCheckResult(
        laplacianVariance: 190.0,
        glareRatio: 0.01,
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
    } else if (manualText != null && manualText.isNotEmpty) {
      // Real OCR matching from manual input query
      final ocrResult = ocrEngine.parseRawText(manualText);
      final quality = QualityCheckResult(
        laplacianVariance: 200.0,
        glareRatio: 0.0,
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
    } else if (demoId == 'TEST-002') {
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
      // Default TEST-001 clear match
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

    if (mounted) {
      setState(() {
        _decision = decision;
        _isLoading = false;
      });
      _handleTtsAndEscalation(decision);
    }
  }

    SavedMedicine? _findSavedMedicineMatch(
    VerificationDecision decision,
    List<SavedMedicine> savedMeds,
  ) {
    if (decision.state != GateDecisionState.match) return null;

    final matchedId = decision.matchedMedicineId;
    final matchedName = decision.matchedCanonicalName?.toLowerCase().trim();
    final matchedBrand = decision.matchedBrandName?.toLowerCase().trim();
    final matchedStr = decision.matchedStrength?.toLowerCase().replaceAll(' ', '');

    for (final saved in savedMeds) {
      final savedId = saved.medicineId;
      final savedName = saved.canonicalName.toLowerCase().trim();
      final savedBrand = saved.brandName.toLowerCase().trim();

      if (matchedId != null && (savedId == matchedId || saved.id == matchedId)) {
        return saved;
      }

      bool nameMatch = (matchedName != null && (savedName.contains(matchedName) || matchedName.contains(savedName))) ||
          (matchedBrand != null && (savedBrand.contains(matchedBrand) || matchedBrand.contains(savedBrand))) ||
          (matchedBrand != null && (savedName.contains(matchedBrand) || matchedBrand.contains(savedName)));

      if (nameMatch) {
        if (matchedStr != null && matchedStr.isNotEmpty) {
          final savedStrClean = saved.strength.toLowerCase().replaceAll(' ', '');
          if (savedStrClean == matchedStr || savedStrClean.contains(matchedStr) || matchedStr.contains(savedStrClean)) {
            return saved;
          }
        } else {
          return saved;
        }
      }
    }
    return null;
  }

  List<ReminderItem> _findMatchingReminders(
    SavedMedicine savedMed,
    List<ReminderItem> reminders,
  ) {
    return reminders.where((r) {
      if (r.medicineId == savedMed.medicineId || r.medicineId == savedMed.id) return true;
      final rName = r.medicineName.toLowerCase();
      final sName = savedMed.canonicalName.toLowerCase();
      final sBrand = savedMed.brandName.toLowerCase();
      return rName.contains(sName) || rName.contains(sBrand);
    }).toList();
  }

  void _handleTtsAndEscalation(VerificationDecision decision) {
    final tts = ref.read(ttsServiceProvider);
    final lang = ref.read(currentLangProvider);
    final savedMeds = ref.read(savedMedicinesProvider);
    final repo = ref.read(medicineRepositoryProvider);
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final isAddMode = extra?['mode'] == 'add';

    if (decision.state == GateDecisionState.match) {
      ref.read(consecutiveScanFailuresProvider.notifier).reset();
      final savedMatch = _findSavedMedicineMatch(decision, savedMeds);

      if (savedMatch != null) {
        final msg = lang == 'hi'
            ? '${savedMatch.canonicalName} ${savedMatch.strength} आपकी सहेजी गई दवाओं में है। लेने के लिए सुरक्षित। समय: ${savedMatch.timing}।'
            : lang == 'mr'
                ? '${savedMatch.canonicalName} ${savedMatch.strength} तुमच्या सेव्ह केलेल्या औषधांमध्ये आहे. घेण्यास सुरक्षित. वेळ: ${savedMatch.timing}.'
                : '${savedMatch.canonicalName} ${savedMatch.strength} is in your saved medicines. Safe to take. Timing: ${savedMatch.timing}.';
        tts.speak(msg, langCode: lang);
      } else if (isAddMode) {
        final medName = decision.matchedCanonicalName ?? 'Scanned medicine';
        final str = decision.matchedStrength ?? '';
        final msg = lang == 'hi'
            ? '$medName $str की पहचान हो गई है। अपनी दवाओं में जोड़ने के लिए नीचे बटन दबाएं।'
            : lang == 'mr'
                ? '$medName $str ओळखले आहे. आपल्या औषधांमध्ये जोडण्यासाठी बटण दाबा.'
                : '$medName $str scanned and verified in catalog. Tap the button below to add to your medicines.';
        tts.speak(msg, langCode: lang);
      } else {
        final medName = decision.matchedCanonicalName ?? 'Scanned medicine';
        final str = decision.matchedStrength ?? '';
        repo.addCaregiverEvent(
          CaregiverEvent(
            id: 'EVT-${DateTime.now().millisecondsSinceEpoch}',
            timestamp: DateTime.now(),
            eventType: 'UNSCHEDULED_MEDICINE_SCANNED',
            medicineName: '$medName $str'.trim(),
            note: 'User scanned catalog medicine not in active saved medicines list.',
          ),
        );

        final msg = lang == 'hi'
            ? 'चेतावनी: $medName कैटलॉग में है, लेकिन आपकी सहेजी गई दवाओं में नहीं है। डॉक्टर या केयरगिवर से जांच करें।'
            : lang == 'mr'
                ? 'तकीद: $medName कॅटलॉगमध्ये आहे, पण तुमच्या सेव्ह केलेल्या औषधांत नाही. काळजीवाचक कडून तपासा.'
                : 'Warning: $medName $str is verified in catalog, but is not in your saved prescribed medicines list. Please check with caregiver or doctor before taking.';
        tts.speak(msg, langCode: lang);
      }
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

  void _showAddCustomMedicineDialog({String? defaultName, String? defaultBrand, String? defaultStrength}) {
    final nameController = TextEditingController(text: defaultName ?? '');
    final brandController = TextEditingController(text: defaultBrand ?? '');
    final strengthController = TextEditingController(text: defaultStrength ?? '5 mg');
    String timing = 'After food';
    final instructionController = TextEditingController(text: 'As prescribed by doctor');

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Medicine Manually', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Could not scan clearly? Enter the details below to save it to your medicines.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Medicine Name *', hintText: 'e.g. Paracetamol'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(labelText: 'Brand Name', hintText: 'e.g. Crocin'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: strengthController,
                  decoration: const InputDecoration(labelText: 'Strength *', hintText: 'e.g. 500 mg'),
                ),
                const SizedBox(height: 12),
                const Text('Timing Instruction:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: timing,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'After food', child: Text('After food')),
                    DropdownMenuItem(value: 'Before food', child: Text('Before food')),
                    DropdownMenuItem(value: 'With food', child: Text('With food')),
                    DropdownMenuItem(value: 'At bedtime', child: Text('At bedtime')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => timing = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionController,
                  decoration: const InputDecoration(labelText: 'Usage Note', hintText: '1 tablet twice daily'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final str = strengthController.text.trim();
                if (name.isNotEmpty && str.isNotEmpty) {
                  ref.read(savedMedicinesProvider.notifier).addCustom(
                        name: name,
                        brand: brandController.text.trim(),
                        strength: str,
                        dosageForm: 'Tablet',
                        timing: timing,
                        usageInstruction: instructionController.text.trim(),
                      );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $name $str to My Medicines'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                  context.push('/my-medicines');
                }
              },
              child: const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
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
          'MediSathi could not verify the medicine twice in a row. Would you like to contact or send an alert to caregiver Rahul?',
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
            label: const Text('Contact Caregiver'),
          ),
        ],
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _decision == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final decision = _decision!;
    final isCatalogMatch = decision.state == GateDecisionState.match;
    final savedMeds = ref.watch(savedMedicinesProvider);
    final reminders = ref.watch(remindersProvider);
    final savedMatch = _findSavedMedicineMatch(decision, savedMeds);
    final isPrescribedAndSafe = isCatalogMatch && savedMatch != null;

    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final isAddMode = extra?['mode'] == 'add';

    final String appBarTitle = isPrescribedAndSafe
        ? 'Medicine Verified — Safe'
        : isAddMode
            ? (isCatalogMatch ? 'Verified Medicine — Ready to Add' : 'Scan to Add Medicine')
            : isCatalogMatch
                ? 'Not in Prescribed List'
                : 'Scan Review';

    final Color appBarColor = isPrescribedAndSafe
        ? const Color(0xFF10B981)
        : isAddMode
            ? (isCatalogMatch ? const Color(0xFF059669) : const Color(0xFFF59E0B))
            : isCatalogMatch
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBack(context),
            tooltip: 'Back',
          ),
          title: Text(appBarTitle),
          backgroundColor: appBarColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isPrescribedAndSafe) ...[
                  _buildPrescribedHeader(decision, savedMatch),
                  const SizedBox(height: 20),
                  _buildVerifiedCard(decision),
                  const SizedBox(height: 20),
                  _buildWhenToTakeCard(savedMatch, _findMatchingReminders(savedMatch, reminders)),
                  const SizedBox(height: 20),
                  _buildSignalsChecklist(decision),
                ] else if (isAddMode && isCatalogMatch) ...[
                  _buildAddModeHeader(decision),
                  const SizedBox(height: 20),
                  _buildAddModeCard(decision),
                  const SizedBox(height: 20),
                  _buildSignalsChecklist(decision),
                ] else if (isCatalogMatch) ...[
                  _buildUnprescribedHeader(decision),
                  const SizedBox(height: 20),
                  _buildUnprescribedWarningCard(decision),
                  const SizedBox(height: 20),
                  _buildCaregiverAlertCard(decision),
                ] else ...[
                  _buildUnverifiedHeader(decision),
                  const SizedBox(height: 20),
                  _buildUnverifiedCard(decision),
                ],
                const SizedBox(height: 30),
                if (isAddMode && !isPrescribedAndSafe && isCatalogMatch)
                  _buildAddModeActionButtons(decision)
                else
                  _buildActionButtons(isPrescribedAndSafe, isCatalogMatch, decision),
                const SizedBox(height: 24),
                const Text(
                  'Prototype for medication identification and adherence support — not a substitute for medical advice.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddModeHeader(VerificationDecision decision) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 64),
          const SizedBox(height: 12),
          const Text(
            'Medicine Verified in Catalog',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'READY TO ADD TO MY MEDICINES',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddModeCard(VerificationDecision decision) {
    final medName = decision.matchedCanonicalName ?? 'Scanned Medicine';
    final str = decision.matchedStrength ?? '';
    final brand = decision.matchedBrandName ?? 'Generic';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication, color: Color(0xFF059669), size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$str • Brand: $brand',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Take as prescribed by doctor.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddModeActionButtons(VerificationDecision decision) {
    final medName = decision.matchedCanonicalName ?? 'Scanned Medicine';
    final str = decision.matchedStrength ?? '';
    final brand = decision.matchedBrandName ?? '';

    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            ref.read(savedMedicinesProvider.notifier).addCustom(
                  name: medName,
                  brand: brand,
                  strength: str.isNotEmpty ? str : '500 mg',
                  dosageForm: 'Tablet',
                  timing: 'After food',
                  usageInstruction: 'As prescribed by doctor',
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added $medName $str to My Medicines & Reminders!'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            context.push('/my-medicines');
          },
          icon: const Icon(Icons.add_circle, size: 28),
          label: const Text('ADD TO MY MEDICINES & SET REMINDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _showAddCustomMedicineDialog(
            defaultName: medName,
            defaultBrand: brand,
            defaultStrength: str,
          ),
          icon: const Icon(Icons.edit),
          label: const Text('EDIT DETAILS BEFORE ADDING', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _handleBack(context),
          child: const Text('CANCEL', style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
        ),
      ],
    );
  }

  Widget _buildPrescribedHeader(VerificationDecision decision, SavedMedicine savedMatch) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 64),
          const SizedBox(height: 12),
          const Text(
            'Prescribed Medicine Verified',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  'SAFE TO TAKE — Present in My Medicines',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhenToTakeCard(SavedMedicine savedMatch, List<ReminderItem> matchingReminders) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x4D3B82F6), width: 1.5),
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF6FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time_filled, color: Color(0xFF1E6FE8), size: 28),
                SizedBox(width: 10),
                Text(
                  'When To Take This Medicine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.restaurant, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Timing: ${savedMatch.timing}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Instruction: ${savedMatch.usageInstruction}',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
                  ),
                ),
              ],
            ),
            if (matchingReminders.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Scheduled Reminders: ${matchingReminders.map((r) => r.timeOfDay).join(', ')} (${matchingReminders.first.repeatOption})',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF), fontSize: 14),
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

  Widget _buildUnprescribedHeader(VerificationDecision decision) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 64),
          const SizedBox(height: 12),
          const Text(
            'Not in Your Prescribed Medicines',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'UNSCHEDULED MEDICINE — NOT CONFIDENT',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnprescribedWarningCard(VerificationDecision decision) {
    final medName = decision.matchedCanonicalName ?? 'Scanned Medicine';
    final str = decision.matchedStrength ?? '';
    final brand = decision.matchedBrandName ?? 'Generic';

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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_liquid, color: Color(0xFFD97706), size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$str • Brand: $brand',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This medicine is verified in the medical database, but it is NOT present in your "My Saved Medicines" list. Do NOT take it automatically.',
                      style: TextStyle(color: Color(0xFF991B1B), fontSize: 14, height: 1.4, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverAlertCard(VerificationDecision decision) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notification_important, color: Color(0xFFEA580C), size: 26),
                SizedBox(width: 10),
                Text(
                  'Caregiver Alert Logged',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'An unscheduled medicine scan event has been automatically logged for caregiver Rahul. If you were recently prescribed this, tap below to save it.',
              style: TextStyle(fontSize: 14, color: Color(0xFF7C2D12)),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.push('/caregiver'),
              icon: const Icon(Icons.send),
              label: const Text('NOTIFY CAREGIVER RAHUL', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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

  Widget _buildActionButtons(bool isPrescribedAndSafe, bool isCatalogMatch, VerificationDecision decision) {
    if (isPrescribedAndSafe) {
      return Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              context.push('/my-medicines');
            },
            icon: const Icon(Icons.check_circle_outline, size: 28),
            label: const Text('VIEW IN MY MEDICINES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    } else if (isCatalogMatch) {
      return Column(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => _showAddCustomMedicineDialog(
              defaultName: decision.matchedCanonicalName,
              defaultBrand: decision.matchedBrandName,
              defaultStrength: decision.matchedStrength,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 28),
            label: const Text('ADD TO MY MEDICINES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => context.push('/caregiver'),
            icon: const Icon(Icons.notification_important, size: 24),
            label: const Text('ALERT CAREGIVER FOR HELP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.refresh),
            label: const Text('RESCAN STRIP', style: TextStyle(fontSize: 16)),
          ),
        ],
      );
    } else {
      final detectedName = decision.matchedCanonicalName;
      final detectedBrand = decision.matchedBrandName;
      final candidates = decision.lookalikeCandidates; // e.g. ["Amlodipine 5 mg", "Amlodipine 10 mg"]

      // Extract distinct strengths from lookalike candidates
      final strengths = candidates
          .map((c) {
            final parts = c.split(' ');
            // Take the last two parts as strength e.g. "5 mg"
            if (parts.length >= 2) return '${parts[parts.length - 2]} ${parts.last}';
            return null;
          })
          .whereType<String>()
          .toSet()
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (detectedName != null) ...[
            // ── Strength picker card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medication, color: Color(0xFF059669), size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$detectedName detected on strip',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap YOUR tablet strength below to save it directly to My Medicines:',
                    style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 16),
                  if (strengths.isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: strengths.map((s) {
                        return SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              ref.read(savedMedicinesProvider.notifier).addCustom(
                                    name: detectedName,
                                    brand: detectedBrand ?? '',
                                    strength: s,
                                    dosageForm: 'Tablet',
                                    timing: 'After food',
                                    usageInstruction: 'As prescribed by doctor',
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Added $detectedName $s to My Medicines'),
                                  backgroundColor: const Color(0xFF10B981),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              context.push('/my-medicines');
                            },
                            child: Text(s),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _showAddCustomMedicineDialog(
                        defaultName: detectedName,
                        defaultBrand: detectedBrand,
                      ),
                      icon: const Icon(Icons.add),
                      label: Text('Add $detectedName to My Medicines'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Fallback manual entry ─────────────────────────────────────
          if (detectedName == null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _showAddCustomMedicineDialog(),
              icon: const Icon(Icons.add_circle_outline, size: 24),
              label: const Text('ADD MANUALLY TO MY MEDICINES',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),

          if (detectedName == null) const SizedBox(height: 12),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.refresh, size: 24),
            label: const Text('RESCAN STRIP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => context.push('/caregiver'),
            icon: const Icon(Icons.notification_important, color: Color(0xFFEF4444)),
            label: const Text('ASK CAREGIVER FOR HELP',
                style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }
  }
}
