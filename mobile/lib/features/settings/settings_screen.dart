import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(currentLangProvider);
    final demoMode = ref.watch(demoModeProvider);

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
          title: const Text('Settings & Configuration'),
          backgroundColor: const Color(0xFF1E6FE8),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile & Account Card
                Consumer(
                  builder: (context, ref, child) {
                    final currentUser = ref.watch(currentUserProvider);
                    final userName = currentUser?.name ?? 'Mrs. Sunanda Patil';
                    final phone = currentUser?.phone.isNotEmpty == true ? currentUser!.phone : 'Guest Mode';
                    final role = currentUser?.role ?? 'Patient';
                    final isGuest = currentUser?.isGuest == true;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: const Color(0xFFEFF6FF),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF1E6FE8),
                                  child: Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        phone,
                                        style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isGuest ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                await ref.read(authRepositoryProvider).init();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile reset to default Sunanda Patil')),
                                  );
                                  context.go('/home');
                                }
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('LOG OUT / SWITCH USER', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

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

                // Voice Read-Aloud Volume Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Voice Read-Aloud Speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Optimized for elderly users with clear speech pronunciation.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(ttsServiceProvider).speak(
                              currentLang == 'hi'
                                  ? 'मेडीसाथी में आपका स्वागत है। आवाज स्पष्ट है।'
                                  : currentLang == 'mr'
                                      ? 'मेडीसाथी मध्ये तुमचे स्वागत आहे। आवाज स्पष्ट आहे.'
                                      : 'Welcome to MediSathi. Voice read aloud test completed.',
                              langCode: currentLang,
                            );
                          },
                          icon: const Icon(Icons.volume_up),
                          label: const Text('Test Voice Speech Output'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Mode Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mode Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable Quick Demo Fallback Samples'),
                          subtitle: const Text('Shows static test samples alongside real OCR scanner'),
                          value: demoMode,
                          onChanged: (val) {
                            ref.read(demoModeProvider.notifier).set(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'MediSathi Mobile MVP v1.0.0 (CODEX 2026 Hackathon Submission)\nDeterministic • Offline-First • Zero-Guess Safety Engine',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                ),

                const SizedBox(height: 16),

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
