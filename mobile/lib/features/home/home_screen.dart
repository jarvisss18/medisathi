import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';
import '../../data/models.dart';
import '../reminders/reminder_ringing_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final savedMeds = ref.watch(savedMedicinesProvider);
    final repo = ref.watch(medicineRepositoryProvider);
    final tts = ref.read(ttsServiceProvider);
    final currentLang = ref.watch(currentLangProvider);

    final activeReminders = reminders.where((r) {
      if (!r.isEnabled) return false;
      if (r.id.startsWith('CUSTOM-') || r.medicineId.startsWith('CUSTOM-')) return true;
      if (savedMeds.isEmpty) return false;
      return savedMeds.any((m) =>
        m.medicineId == r.medicineId ||
        m.id == r.medicineId ||
        r.medicineName.toLowerCase().contains(m.canonicalName.toLowerCase())
      );
    }).toList();
    final takenCount = repo.doseLogs.where((l) => l.status == DoseStatus.taken).length;
    final totalCount = activeReminders.length;

    final currentUser = ref.watch(currentUserProvider);
    final userName = currentUser?.name ?? 'Mrs. Sunanda';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Keep user on Home Screen safely
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.medical_services, color: Color(0xFF1E6FE8)),
              SizedBox(width: 8),
              Text(
                'MediSathi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.volume_up, size: 30, color: Color(0xFF1E6FE8)),
              onPressed: () {
                final message = currentLang == 'hi'
                    ? 'नमस्ते $userName जी! मेडीसाथी में आपका स्वागत है।'
                    : currentLang == 'mr'
                        ? 'नमस्ते $userName जी! मेडीसाथी मध्ये तुमचे स्वागत आहे.'
                        : 'Welcome $userName to MediSathi. Tap scan medicine to verify your strip.';
                tts.speak(message, langCode: currentLang);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reading Aloud: $message')),
                );
              },
              tooltip: 'Read Aloud',
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 28),
              onPressed: () => context.push('/settings'),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E6FE8), Color(0xFF0F4098)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentLang == 'hi'
                                ? 'नमस्ते, $userName जी!'
                                : currentLang == 'mr'
                                    ? 'नमस्ते, $userName जी!'
                                    : 'Namaste, $userName!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (currentUser?.isGuest == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('GUEST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentUser?.role ?? 'Patient',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentLang == 'hi'
                          ? 'आज हम आपकी सुरक्षा में कैसे मदद कर सकते हैं?'
                          : currentLang == 'mr'
                              ? 'आज आम्ही तुम्हाला कशी मदत करू शकतो?'
                              : 'How can we help you stay safe today?',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Main Action Grid (4 Large Tiles)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionTile(
                    context,
                    title: 'Scan Medicine',
                    icon: Icons.qr_code_scanner,
                    color: const Color(0xFF1E6FE8),
                    onTap: () => context.push('/scan'),
                  ),
                  _buildActionTile(
                    context,
                    title: 'My Medicines',
                    icon: Icons.medication,
                    color: const Color(0xFF10B981),
                    onTap: () => context.push('/my-medicines'),
                  ),
                  _buildActionTile(
                    context,
                    title: 'Reminders',
                    icon: Icons.alarm,
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.push('/reminders'),
                  ),
                  _buildActionTile(
                    context,
                    title: 'Caregiver Alert',
                    icon: Icons.contact_emergency,
                    color: const Color(0xFFEF4444),
                    onTap: () => context.push('/caregiver'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's Doses Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Doses",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text('$takenCount Taken / $totalCount Active'),
                            backgroundColor: const Color(0xFFE2E8F0),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (activeReminders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No active medication reminders for today. Tap Scan or Medicines to add one.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: activeReminders.length > 3 ? 3 : activeReminders.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final r = activeReminders[index];
                            final isLoggedTaken = repo.doseLogs.any((l) => l.reminderId == r.id && l.status == DoseStatus.taken);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: isLoggedTaken ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE),
                                    child: Icon(
                                      isLoggedTaken ? Icons.check_circle : Icons.notifications_active_rounded,
                                      color: isLoggedTaken ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => ReminderRingingDialog.show(context, r),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.medicineName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            'Due at ${r.timeOfDay} • ${r.doseText}',
                                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B)),
                                    onPressed: () {
                                      ReminderRingingDialog.show(context, r);
                                    },
                                    tooltip: 'Ring Alarm',
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(60, 36),
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      backgroundColor: isLoggedTaken ? const Color(0xFF64748B) : const Color(0xFF10B981),
                                    ),
                                    onPressed: () {
                                      repo.markDoseStatus(r.id, r.medicineName, DoseStatus.taken);
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Marked ${r.medicineName} as TAKEN ✓'),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    },
                                    child: Text(isLoggedTaken ? 'Done ✓' : 'Taken'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Safety Disclaimer Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MediSathi safety assistant — deterministic offline medicine verification and adherence support.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 1) {
              context.push('/my-medicines');
            }
            if (index == 2) {
              context.push('/reminders');
            }
            if (index == 3) {
              context.push('/settings');
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.medication), label: 'Medicines'),
            NavigationDestination(icon: Icon(Icons.alarm), label: 'Reminders'),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          border: Border.all(color: color.withAlpha(77), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color,
              child: Icon(icon, size: 36, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
