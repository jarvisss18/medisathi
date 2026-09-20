import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_providers.dart';
import '../../data/models.dart';
import '../../core/notifications/notification_service.dart';

class ReminderRingingDialog extends ConsumerStatefulWidget {
  final ReminderItem reminder;
  final SavedMedicine? savedMedicine;

  const ReminderRingingDialog({
    super.key,
    required this.reminder,
    this.savedMedicine,
  });

  static Future<void> show(BuildContext context, ReminderItem reminder, {SavedMedicine? savedMedicine}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReminderRingingDialog(
        reminder: reminder,
        savedMedicine: savedMedicine,
      ),
    );
  }

  @override
  ConsumerState<ReminderRingingDialog> createState() => _ReminderRingingDialogState();
}

class _ReminderRingingDialogState extends ConsumerState<ReminderRingingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _pulseAnimation;
  Timer? _ttsTimer;
  bool _isRinging = true;

  @override
  void initState() {
    super.initState();

    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRingingLoop();
    });
  }

  void _startRingingLoop() {
    final tts = ref.read(ttsServiceProvider);
    final lang = ref.read(currentLangProvider);
    final medName = widget.reminder.medicineName;

    void speakMessage() {
      if (!_isRinging) return;
      final msg = lang == 'hi'
          ? 'दवा का समय! $medName लेने का समय हो गया है।'
          : lang == 'mr'
              ? 'औषधाची वेळ! $medName घेण्याची वेळ झाली आहे.'
              : 'Medicine Time! It is time to take your medicine $medName.';
      tts.speak(msg, langCode: lang);
    }

    speakMessage();

    _ttsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _isRinging) {
        speakMessage();
      }
    });
  }

  void _stopRinging() {
    _isRinging = false;
    _ttsTimer?.cancel();
    ref.read(ttsServiceProvider).stop();
  }

  @override
  void dispose() {
    _stopRinging();
    _bellController.dispose();
    super.dispose();
  }

  void _handleMarkTaken() {
    _stopRinging();
    final repo = ref.read(medicineRepositoryProvider);
    repo.markDoseStatus(widget.reminder.id, widget.reminder.medicineName, DoseStatus.taken);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Marked ${widget.reminder.medicineName} as TAKEN'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleRemindIn15Min() {
    _stopRinging();
    final now = DateTime.now().add(const Duration(minutes: 15));

    NotificationService().scheduleDoseReminder(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Snoozed: ${widget.reminder.medicineName}',
      body: 'Time to take your ${widget.reminder.doseText} now.',
      hour: now.hour,
      minute: now.minute,
    );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ Alarm set for ${widget.reminder.medicineName} in 15 minutes'),
          backgroundColor: const Color(0xFF3B82F6),
        ),
      );
    }
  }

  void _handleSnooze5Min() {
    _stopRinging();
    final now = DateTime.now().add(const Duration(minutes: 5));

    NotificationService().scheduleDoseReminder(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Snoozed: ${widget.reminder.medicineName}',
      body: 'Snoozed dose: ${widget.reminder.doseText}',
      hour: now.hour,
      minute: now.minute,
    );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏱️ Snoozed ${widget.reminder.medicineName} for 5 minutes'),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final medName = widget.reminder.medicineName;
    final dose = widget.reminder.doseText;
    final timeStr = widget.reminder.timeOfDay;
    final timingInstruction = widget.savedMedicine?.timing ?? 'After breakfast';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF044E36), Color(0xFF0B6E4F), Color(0xFF10B981)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              // Glowing Animated Alarm Bell Icon
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x33FBBF24),
                    border: Border.all(color: const Color(0xFFFBBF24), width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66FBBF24),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFFBBF24),
                    size: 64,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title & Subtitle
              const Text(
                'Medicine Time!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "It's time to take your medicine.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFD1FAE5),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Main Information Card (White background like image)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Pill Thumbnail Box
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: const Icon(
                            Icons.medication_liquid_rounded,
                            color: Color(0xFFF43F5E),
                            size: 38,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.fitness_center, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    dose,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.restaurant, size: 16, color: Color(0xFF059669)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      timingInstruction,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_filled, size: 16, color: Color(0xFF1E6FE8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1E6FE8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Primary Button: Mark as Taken
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _handleMarkTaken,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 24),
                      label: const Text(
                        'Mark as Taken',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Secondary Action Buttons: Remind in 15 min & Snooze
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF059669), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _handleRemindIn15Min,
                            icon: const Icon(Icons.alarm_add, color: Color(0xFF059669), size: 18),
                            label: const Text(
                              'Remind in 15 min',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _handleSnooze5Min,
                            icon: const Icon(Icons.timer_outlined, color: Color(0xFF0284C7), size: 18),
                            label: const Text(
                              'Snooze',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Leaf Tagline
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco_rounded, color: Color(0xFF34D399), size: 20),
                  SizedBox(width: 6),
                  Text(
                    '"Your health matters"',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
