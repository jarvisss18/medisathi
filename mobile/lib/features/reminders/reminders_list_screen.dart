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

class _RemindersListScreenState extends ConsumerState<RemindersListScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(remindersProvider);
    final repo = ref.watch(medicineRepositoryProvider);
    final logs = repo.doseLogs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
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
            Tab(text: 'Dose History & Logs'),
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
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text('Add Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildUpcomingTab(List<ReminderItem> reminders) {
    if (reminders.isEmpty) {
      return const Center(
        child: Text('No active reminders. Tap + to set one!'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final r = reminders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.alarm, color: Color(0xFF1E6FE8), size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.medicineName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${r.doseText} • Time: ${r.timeOfDay}',
                            style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: r.isEnabled,
                      activeThumbColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        ref.read(remindersProvider.notifier).toggle(r.id, val);
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ref.read(remindersProvider.notifier).delete(r.id);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(130, 44),
                      ),
                      onPressed: () {
                        final repo = ref.read(medicineRepositoryProvider);
                        repo.markDoseStatus(r.id, r.medicineName, DoseStatus.taken);
                        setState(() {});

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Marked ${r.medicineName} as TAKEN ✓'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('MARK TAKEN', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Text('No dose history recorded yet today.', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
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

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              isTaken ? Icons.check_circle : Icons.cancel,
              color: isTaken ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              size: 32,
            ),
            title: Text(log.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: ${log.status.name.toUpperCase()} • ${log.actedAt.substring(11, 16)}'),
          ),
        );
      },
    );
  }
}
