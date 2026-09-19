import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/app_providers.dart';

class InteractionScreen extends ConsumerWidget {
  const InteractionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
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
}
