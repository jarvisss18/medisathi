import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';

class MyMedicinesScreen extends ConsumerWidget {
  const MyMedicinesScreen({super.key});

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _showAddCustomMedicineDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final strengthController = TextEditingController();
    String timing = 'After food';
    final instructionController = TextEditingController(text: 'As prescribed by doctor');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      setDialogState(() {
                        timing = val;
                      });
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
              onPressed: () => Navigator.pop(context),
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $name $str to My Medicines'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedMeds = ref.watch(savedMedicinesProvider);
    final repo = ref.watch(medicineRepositoryProvider);

    // Check if any two saved medicines have an interaction
    bool hasInteractionWarning = false;
    for (final med in savedMeds) {
      final rules = repo.checkInteractionsForCandidate(med.canonicalName);
      if (rules.isNotEmpty) {
        hasInteractionWarning = true;
        break;
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
          title: const Text('My Saved Medicines'),
          backgroundColor: const Color(0xFF1E6FE8),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddCustomMedicineDialog(context, ref),
              tooltip: 'Add Custom Medicine',
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push('/scan', extra: {'mode': 'add'}),
              tooltip: 'Scan New Strip',
            ),
          ],
        ),
        body: Column(
          children: [
            if (hasInteractionWarning)
              InkWell(
                onTap: () => context.push('/interaction'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  color: const Color(0xFFFEF2F2),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Potential Drug Interaction Detected in your list! Tap to view.',
                          style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Color(0xFFDC2626)),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: savedMeds.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.medication_liquid, size: 64, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 16),
                            const Text(
                              'No saved medicines yet.',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Scan a strip photo or add custom medicine details.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _showAddCustomMedicineDialog(context, ref),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Custom Medicine'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: savedMeds.length,
                      itemBuilder: (context, index) {
                        final med = savedMeds[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.medication, color: Color(0xFF1E6FE8), size: 32),
                            ),
                            title: Text(
                              '${med.canonicalName} ${med.strength}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Brand: ${med.brandName} • ${med.dosageForm}'),
                                Text('Timing: ${med.timing}', style: const TextStyle(color: Color(0xFF1E6FE8))),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.alarm_add, color: Color(0xFF1E6FE8)),
                                  onPressed: () {
                                    context.push('/set-reminder', extra: {
                                      'medicine_id': med.medicineId,
                                      'name': '${med.canonicalName} ${med.strength}',
                                    });
                                  },
                                  tooltip: 'Set Reminder',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    ref.read(savedMedicinesProvider.notifier).remove(med.id);
                                  },
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'fab_add_custom',
              backgroundColor: const Color(0xFF10B981),
              onPressed: () => _showAddCustomMedicineDialog(context, ref),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'fab_scan_strip',
              backgroundColor: const Color(0xFF1E6FE8),
              onPressed: () => context.push('/scan', extra: {'mode': 'add'}),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Scan Strip to Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
