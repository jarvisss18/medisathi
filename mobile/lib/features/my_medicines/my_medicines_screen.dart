import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';

class MyMedicinesScreen extends ConsumerWidget {
  const MyMedicinesScreen({super.key});

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Saved Medicines'),
        backgroundColor: const Color(0xFF1E6FE8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/scan'),
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
                ? const Center(
                    child: Text('No saved medicines. Tap + to scan and add your first strip!'),
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
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              ref.read(savedMedicinesProvider.notifier).remove(med.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1E6FE8),
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text('Scan Strip to Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
