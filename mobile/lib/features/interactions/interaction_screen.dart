import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/app_providers.dart';
import '../../data/models.dart';

class InteractionScreen extends ConsumerStatefulWidget {
  const InteractionScreen({super.key});

  @override
  ConsumerState<InteractionScreen> createState() => _InteractionScreenState();
}

class _InteractionScreenState extends ConsumerState<InteractionScreen> {
  final _drug1Controller = TextEditingController();
  final _drug2Controller = TextEditingController();
  List<InteractionRule>? _customTestResults;

  @override
  void dispose() {
    _drug1Controller.dispose();
    _drug2Controller.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _testDrugPair() {
    final d1 = _drug1Controller.text.trim();
    final d2 = _drug2Controller.text.trim();
    if (d1.isEmpty || d2.isEmpty) return;

    final repo = ref.read(medicineRepositoryProvider);
    final results = repo.checkInteractionBetweenTwoDrugs(d1, d2);
    setState(() {
      _customTestResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicineRepositoryProvider);
    final savedMeds = ref.watch(savedMedicinesProvider);
    final lang = ref.watch(currentLangProvider);

    // Find active interactions among saved medicines
    final activeInteractions = <Map<String, String>>[];

    for (int i = 0; i < savedMeds.length; i++) {
      for (int j = i + 1; j < savedMeds.length; j++) {
        final rules = repo.checkInteractionsForCandidate(savedMeds[i].canonicalName);
        for (final r in rules) {
          if (r.drugA.toLowerCase().contains(savedMeds[j].canonicalName.toLowerCase()) ||
              r.drugB.toLowerCase().contains(savedMeds[j].canonicalName.toLowerCase()) ||
              savedMeds[j].canonicalName.toLowerCase().contains(r.drugA.toLowerCase()) ||
              savedMeds[j].canonicalName.toLowerCase().contains(r.drugB.toLowerCase())) {
            activeInteractions.add({
              'medA': savedMeds[i].canonicalName,
              'medB': savedMeds[j].canonicalName,
              'ruleId': r.ruleId,
              'desc': lang == 'hi'
                  ? r.riskDescriptionHi
                  : lang == 'mr'
                      ? r.riskDescriptionMr
                      : r.riskDescriptionEn,
              'clinical': r.clinicalGuidance,
              'source': r.source,
            });
          }
        }
      }
    }

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
            tooltip: 'Back to Home',
          ),
          title: const Text('Drug Interaction Warnings'),
          backgroundColor: const Color(0xFF1E6FE8),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF1E6FE8), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'MediSathi checks your saved medicines against curated clinical interaction rules. Only verified rules are shown.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF1E40AF), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Interactive 2-Drug Pair Tester Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science, color: Color(0xFF1E6FE8)),
                            SizedBox(width: 8),
                            Text(
                              'Test 2 Medicines Pair',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _drug1Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Drug A',
                                  hintText: 'e.g. Aspirin',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _drug2Controller,
                                decoration: const InputDecoration(
                                  labelText: 'Drug B',
                                  hintText: 'e.g. Ibuprofen',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E6FE8),
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: _testDrugPair,
                          icon: const Icon(Icons.search),
                          label: const Text('Check Pair Safety'),
                        ),
                        if (_customTestResults != null) ...[
                          const SizedBox(height: 16),
                          if (_customTestResults!.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: const Text(
                                '✓ No severe interaction rule found between these two medicines in database.',
                                style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            ..._customTestResults!.map(
                              (r) => Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEF4444)),
                                ),
                                child: Text(
                                  '⚠️ INTERACTION FOUND: ${r.riskDescriptionEn}\nGuidance: ${r.clinicalGuidance}',
                                  style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (activeInteractions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 56),
                        SizedBox(height: 12),
                        Text(
                          'No Stored Interaction Warnings',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No stored interaction rule matched your current list of saved medicines. This is not a guarantee of safety. Ask your doctor or pharmacist.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeInteractions.length,
                    itemBuilder: (context, index) {
                      final item = activeInteractions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEF4444), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item['medA']} + ${item['medB']}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['desc']!,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF7F1D1D), height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Guidance: ${item['clinical']}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rule ID: ${item['ruleId']} • Source: ${item['source']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),
                const Text(
                  'MediSathi safety assistant — deterministic offline medicine verification and adherence support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
