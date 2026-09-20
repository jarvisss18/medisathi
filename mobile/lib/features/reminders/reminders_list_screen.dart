import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';
import '../../data/models.dart';

class RemindersListScreen extends ConsumerStatefulWidget {
  const RemindersListScreen({super.key});

  @override
  ConsumerState<RemindersListScreen> createState() => _RemindersListScreenState();
}

class _RemindersListScreenState extends ConsumerState<RemindersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  /// Convert stored 24h "HH:mm" to display "H:MM AM/PM"
  String _formatDisplayTime(String stored) {
    try {
      final parts = stored.split(':');
      if (parts.length == 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final suffix = h >= 12 ? 'PM' : 'AM';
        final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        return '$displayH:${m.toString().padLeft(2, '0')} $suffix';
      }
    } catch (_) {}
    return stored; // fallback: return as-is
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicineRepositoryProvider);
    final reminders = ref.watch(remindersProvider);
    final logs = repo.doseLogs;

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
          title: const Text('Medication Reminders'),
          backgroundColor: const Color(0xFF1E6FE8),
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [
              Tab(text: 'Upcoming Doses'),
              Tab(text: 'History & Logs'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildUpcomingTab(reminders),
            _buildLogsTab(logs),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF1E6FE8),
          onPressed: () => context.push('/set-reminder'),
          icon: const Icon(Icons.add_alarm, color: Colors.white),
          label: const Text(
            'Add Reminder',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(List<ReminderItem> reminders) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm_off, size: 72, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            const Text(
              'No reminders set yet.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button below to schedule\nyour first medication reminder.',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final enabledCount = reminders.where((r) => r.isEnabled).length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: reminders.length + 1,
      itemBuilder: (context, index) {
        // Index 0 → summary header banner
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Color(0xFF1E6FE8), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$enabledCount of ${reminders.length} reminder(s) active · daily alarms scheduled',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Indexes 1..N → reminder cards (no duplication)
        final r = reminders[index - 1];
        final displayTime = _formatDisplayTime(r.timeOfDay);

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: r.isEnabled
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.alarm,
                        color: r.isEnabled
                            ? const Color(0xFF1E6FE8)
                            : const Color(0xFF94A3B8),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.medicineName,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: r.isEnabled
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 13, color: Color(0xFF1E6FE8)),
                                  const SizedBox(width: 3),
                                  Text(
                                    displayTime,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1E6FE8),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.medication_outlined,
                                      size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 3),
                                  Text(
                                    r.doseText,
                                    style: const TextStyle(
                                        fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              if (r.repeatOption == 'Daily')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Daily',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF059669),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: r.isEnabled,
                      activeThumbColor: const Color(0xFF10B981),
                      activeTrackColor: const Color(0xFFD1FAE5),
                      onChanged: (val) {
                        ref.read(remindersProvider.notifier).toggle(r.id, val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Delete Reminder',
                      onPressed: () {
                        ref.read(remindersProvider.notifier).delete(r.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Reminder for ${r.medicineName} deleted'),
                            backgroundColor: Colors.red.shade400,
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () {
                        final repo = ref.read(medicineRepositoryProvider);
                        repo.markDoseStatus(r.id, r.medicineName, DoseStatus.missed);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ ${r.medicineName} marked as MISSED. Caregiver alerted.'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('MISSED', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        final repo = ref.read(medicineRepositoryProvider);
                        repo.markDoseStatus(r.id, r.medicineName, DoseStatus.taken);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ ${r.medicineName} marked as TAKEN'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('TAKEN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogsTab(List<DoseLog> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No dose history recorded yet today.',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            SizedBox(height: 6),
            Text(
              'Recorded doses will appear here on your timeline.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[logs.length - 1 - index];
        final isTaken = log.status == DoseStatus.taken;

        String timeStr = '';
        try {
          timeStr = log.actedAt.substring(11, 16);
        } catch (_) {}

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              isTaken ? Icons.check_circle : Icons.cancel,
              color: isTaken ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 32,
            ),
            title: Text(log.medicineName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Status: ${log.status.name.toUpperCase()} • at $timeStr'),
          ),
        );
      },
    );
  }
}
