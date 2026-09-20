import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';
import '../../data/models.dart';

class MedicineDetailsScreen extends ConsumerStatefulWidget {
  const MedicineDetailsScreen({super.key});

  @override
  ConsumerState<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends ConsumerState<MedicineDetailsScreen> {
  String _timing = 'After food';
  final String _customInstruction = 'As prescribed by doctor';
  List<InteractionRule> _interactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInteractions();
    });
  }

  void _checkInteractions() {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final name = extra?['name'] as String? ?? 'Amlodipine';

    final repo = ref.read(medicineRepositoryProvider);
    final rules = repo.checkInteractionsForCandidate(name);
    setState(() {
      _interactions = rules;
    });
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
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final medicineId = extra?['medicine_id'] as String? ?? 'MED-003';
    final name = extra?['name'] as String? ?? 'Amlodipine';
    final strength = extra?['strength'] as String? ?? '5 mg';
    final brand = extra?['brand'] as String? ?? 'Amlokind';

    final repo = ref.read(medicineRepositoryProvider);
    final catalogEntry = repo.findCatalogEntry(medicineId);
    final usageInfo = catalogEntry?['instruction_text'] as String? ?? 'High blood pressure & cardiovascular protection';

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
          title: const Text('Medicine Details'),
          backgroundColor: const Color(0xFF1E6FE8),
          foregroundColor: Colors.white,
        ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.medication_liquid, color: Color(0xFF1E6FE8), size: 48),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$name $strength',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Brand: $brand • Tablet',
                              style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Use For & Instructions Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category & Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        usageInfo,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF334155), height: 1.4),
                      ),
                      const Divider(height: 28),
                      const Text('When to Take', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _timing,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'After food', child: Text('After food (खाना खाने के बाद)')),
                          DropdownMenuItem(value: 'Before food', child: Text('Before food (खाना खाने से पहले)')),
                          DropdownMenuItem(value: 'With food', child: Text('With food (खाने के साथ)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _timing = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Interaction Check Card
              _buildInteractionCard(name),

              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6FE8),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final savedMed = SavedMedicine(
                    id: 'SAVED-${DateTime.now().millisecondsSinceEpoch}',
                    medicineId: medicineId,
                    canonicalName: name,
                    brandName: brand,
                    strength: strength,
                    dosageForm: 'Tablet',
                    usageInstruction: _customInstruction,
                    timing: _timing,
                    addedAt: DateTime.now().toIso8601String(),
                  );
                  ref.read(savedMedicinesProvider.notifier).add(savedMed);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $name $strength to My Medicines'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );

                  context.push('/my-medicines');
                },
                icon: const Icon(Icons.add_task, size: 24),
                label: const Text('ADD TO MY MEDICINES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  context.push('/set-reminder', extra: {
                    'medicine_id': medicineId,
                    'name': '$name $strength',
                  });
                },
                icon: const Icon(Icons.alarm_add, size: 24),
                label: const Text('SET DOSAGE REMINDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    ),
  );
  }

  Widget _buildInteractionCard(String name) {
    if (_interactions.isNotEmpty) {
      final rule = _interactions.first;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Potential Drug Interaction Detected',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${rule.drugA} + ${rule.drugB}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D)),
            ),
            const SizedBox(height: 6),
            Text(
              rule.riskDescriptionEn,
              style: const TextStyle(fontSize: 15, color: Color(0xFF991B1B), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Please consult your doctor or pharmacist before taking these medicines together.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rule ID: ${rule.ruleId} • Source: ${rule.source}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No stored interaction rule matched your current medicines. This is not a guarantee of safety. Ask your doctor or pharmacist.',
                style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.3),
              ),
            ),
          ],
        ),
      );
    }
  }
}
