import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(currentLangProvider);
    final demoMode = ref.watch(demoModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Settings & Demo Mode'),
        backgroundColor: const Color(0xFF1E6FE8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Selection Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('App Language (भाषा बदलें)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'en', label: Text('English')),
                          ButtonSegment(value: 'hi', label: Text('हिंदी')),
                          ButtonSegment(value: 'mr', label: Text('मराठी')),
                        ],
                        selected: {currentLang},
                        onSelectionChanged: (Set<String> selection) {
                          ref.read(currentLangProvider.notifier).set(selection.first);
                          ref.read(ttsServiceProvider).speak(
                            selection.first == 'hi'
                                ? 'हिंदी भाषा चुनी गई'
                                : selection.first == 'mr'
                                    ? 'मराठी भाषा निवडली'
                                    : 'Language set to English',
                            langCode: selection.first,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Demo Camera Mode Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Force Demo Camera Fallback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Uses synthetic/offline images if physical camera is unavailable'),
                        value: demoMode,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          ref.read(demoModeProvider.notifier).set(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Patient Profile Info
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Patient Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Name: Mrs. Sunanda Patil (Demographic Seed)', style: TextStyle(fontSize: 15, color: Color(0xFF334155))),
                      Text('Age: 68 years • Location: Pune, Maharashtra', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                      Text('Primary Languages: Hindi / Marathi / English', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Reset Demo State Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ref.read(consecutiveScanFailuresProvider.notifier).reset();
                  ref.read(activeVerificationDecisionProvider.notifier).set(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo failure counters and active gate state reset.')),
                  );
                },
                icon: const Icon(Icons.restart_alt, color: Color(0xFFEF4444)),
                label: const Text('RESET DEMO GATE STATE', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 30),

              const Text(
                'MediSathi Mobile MVP v1.0.0 (CODEX 2026 Hackathon Submission)\nDeterministic • Offline-First • Zero-Guess Safety Engine',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),

              const SizedBox(height: 16),

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
