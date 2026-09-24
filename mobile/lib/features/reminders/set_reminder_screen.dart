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
  final _customNameController = TextEditingController();
  final _doseController = TextEditingController(text: '1 Tablet');
  
  SavedMedicine? _selectedSavedMed;
  bool _isCustomMode = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String _repeatOption = 'Daily';
  bool _initializedFromExtra = false;

  @override
  void dispose() {
    _customNameController.dispose();
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

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedMeds = ref.watch(savedMedicinesProvider);
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

    if (!_initializedFromExtra) {
      _initializedFromExtra = true;
      final passedName = extra?['name'] as String?;
      if (passedName != null && passedName.isNotEmpty) {
        final match = savedMeds.where((m) => m.canonicalName.toLowerCase() == passedName.toLowerCase()).firstOrNull;
        if (match != null) {
          _selectedSavedMed = match;
        } else {
          _isCustomMode = true;
          _customNameController.text = passedName;
        }
      } else if (savedMeds.isNotEmpty) {
        _selectedSavedMed = savedMeds.first;
      } else {
        _isCustomMode = true;
      }
    }

    final formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

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
                // Selection Mode Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !_isCustomMode ? const Color(0xFF1E6FE8) : Colors.transparent,
                            foregroundColor: !_isCustomMode ? Colors.white : const Color(0xFF64748B),
                            elevation: !_isCustomMode ? 2 : 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              _isCustomMode = false;
                              if (_selectedSavedMed == null && savedMeds.isNotEmpty) {
                                _selectedSavedMed = savedMeds.first;
                              }
                            });
                          },
                          child: const Text('My Medicines', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCustomMode ? const Color(0xFF1E6FE8) : Colors.transparent,
                            foregroundColor: _isCustomMode ? Colors.white : const Color(0xFF64748B),
                            elevation: _isCustomMode ? 2 : 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              _isCustomMode = true;
                            });
                          },
                          child: const Text('Custom Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isCustomMode && savedMeds.isNotEmpty) ...[
                          const Text('Select Saved Medicine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<SavedMedicine>(
                            isExpanded: true,
                            initialValue: _selectedSavedMed ?? savedMeds.first,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.medication, color: Color(0xFF1E6FE8)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: savedMeds.map((med) {
                              return DropdownMenuItem<SavedMedicine>(
                                value: med,
                                child: Text(
                                  '${med.canonicalName} ${med.strength}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSavedMed = val;
                                });
                              }
                            },
                          ),
                        ] else ...[
                          const Text('Medicine Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _customNameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFF1E6FE8)),
                              hintText: 'e.g., Paracetamol 500 mg',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],

                        const Divider(height: 28),

                        const Text('Dose Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _doseController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.local_pharmacy_outlined, color: Color(0xFF10B981)),
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

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6FE8),
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final router = GoRouter.of(context);

                    final String finalMedName;
                    final String finalMedId;

                    if (!_isCustomMode && _selectedSavedMed != null) {
                      finalMedName = '${_selectedSavedMed!.canonicalName} ${_selectedSavedMed!.strength}'.trim();
                      finalMedId = _selectedSavedMed!.medicineId;
                    } else {
                      final nameInput = _customNameController.text.trim();
                      if (nameInput.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a medicine name'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      finalMedName = nameInput;
                      finalMedId = ref.read(savedMedicinesProvider.notifier).addCustom(
                        name: finalMedName,
                        brand: 'Custom',
                        strength: _doseController.text.trim(),
                        dosageForm: 'Tablet',
                        timing: 'After food',
                        usageInstruction: 'As prescribed',
                      );
                    }

                    // Capture everything that needs BuildContext BEFORE the async gap.
                    final displayTime = _selectedTime.format(context);
                    final doseText = _doseController.text.trim();

                    final remId = 'REM-${DateTime.now().millisecondsSinceEpoch}';
                    final newReminder = ReminderItem(
                      id: remId,
                      medicineId: finalMedId,
                      medicineName: finalMedName,
                      doseText: doseText,
                      timeOfDay: formattedTime, // always 24h "HH:mm"
                      repeatOption: _repeatOption,
                      isEnabled: true,
                    );

                    ref.read(remindersProvider.notifier).add(newReminder);

                    // Use a stable int ID derived from the reminder string ID
                    final notifId = remId.hashCode.abs() % 100000;
                    await NotificationService().scheduleDoseReminder(
                      id: notifId,
                      title: 'Time for $finalMedName 💊',
                      body: 'Dose: $doseText — Tap to open MediSathi.',
                      hour: _selectedTime.hour,
                      minute: _selectedTime.minute,
                      dailyRepeat: _repeatOption == 'Daily',
                    );

                    ref.read(ttsServiceProvider).speak(
                      'Reminder saved for $finalMedName at $displayTime',
                    );

                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('✅ Reminder set for $finalMedName at $displayTime'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                      if (router.canPop()) {
                        router.pop();
                      } else {
                        router.go('/reminders');
                      }
                    }
                  },
                  icon: const Icon(Icons.check, size: 28),
                  label: const Text('SAVE REMINDER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => context.push('/scan', extra: {'mode': 'add'}),
                  icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF1E6FE8)),
                  label: const Text('SCAN STRIP TO ADD MEDICINE', style: TextStyle(fontSize: 15, color: Color(0xFF1E6FE8), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
