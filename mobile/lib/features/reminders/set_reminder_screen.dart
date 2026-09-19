import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_service.dart';
import '../../data/app_providers.dart';
import '../../data/models.dart';

class SetReminderScreen extends ConsumerStatefulWidget {
  const SetReminderScreen({super.key});

  @override
  ConsumerState<SetReminderScreen> createState() => _SetReminderScreenState();
}

class _SetReminderScreenState extends ConsumerState<SetReminderScreen> {
  final _doseController = TextEditingController(text: '1 Tablet');
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String _repeatOption = 'Daily';

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final medicineName = extra?['name'] as String? ?? 'Amlodipine 5 mg';
    final medicineId = extra?['medicine_id'] as String? ?? 'MED-003';

    final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Set Dosage Reminder'),
        backgroundColor: const Color(0xFF1E6FE8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Medicine', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(
                        medicineName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E6FE8)),
                      ),
                      const Divider(height: 28),
                      const Text('Dose Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _doseController,
                        decoration: InputDecoration(
                          hintText: 'e.g., 1 Tablet, 5 ml',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Reminder Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled, color: Color(0xFF1E6FE8), size: 28),
                              const SizedBox(width: 12),
                              Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              const Text('CHANGE', style: TextStyle(color: Color(0xFF1E6FE8), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Repeat Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _repeatOption,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Daily', child: Text('Daily (हर दिन)')),
                          DropdownMenuItem(value: 'Once', child: Text('Once (एक बार)')),
                          DropdownMenuItem(value: 'Custom', child: Text('Custom Weekdays')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _repeatOption = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E6FE8),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  final timeFormatted = _selectedTime.format(context);

                  final newReminder = ReminderItem(
                    id: 'REM-${DateTime.now().millisecondsSinceEpoch}',
                    medicineId: medicineId,
                    medicineName: medicineName,
                    doseText: _doseController.text.trim(),
                    timeOfDay: formattedTime,
                    repeatOption: _repeatOption,
                    isEnabled: true,
                  );

                  ref.read(remindersProvider.notifier).add(newReminder);

                  await NotificationService().scheduleDoseReminder(
                    id: DateTime.now().millisecondsSinceEpoch % 100000,
                    title: 'Time for $medicineName',
                    body: 'Dose: ${_doseController.text.trim()} — Tap to mark taken.',
                    hour: _selectedTime.hour,
                    minute: _selectedTime.minute,
                  );

                  ref.read(ttsServiceProvider).speak('Reminder saved for $medicineName at ${formattedTime.replaceAll(':', ' ')}');

                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Reminder set for $medicineName at $timeFormatted'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                    router.go('/reminders');
                  }
                },
                icon: const Icon(Icons.check, size: 28),
                label: const Text('SAVE REMINDER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => context.pop(),
                child: const Text('CANCEL', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
