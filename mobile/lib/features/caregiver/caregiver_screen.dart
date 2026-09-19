import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_providers.dart';

class CaregiverScreen extends ConsumerStatefulWidget {
  const CaregiverScreen({super.key});

  @override
  ConsumerState<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends ConsumerState<CaregiverScreen> {
  final _nameController = TextEditingController(text: 'Rahul Patil');
  final _phoneController = TextEditingController(text: '+91 98200 12345');
  final _relationController = TextEditingController(text: 'Son');

  bool _shareScanAlerts = true;
  bool _shareMissedDoses = true;
  bool _includePhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicineRepositoryProvider);
    final events = repo.caregiverEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Caregiver Escalation'),
        backgroundColor: const Color(0xFF1E6FE8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Caregiver Profile Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_pin, color: Color(0xFF1E6FE8), size: 36),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${_relationController.text} • ${_phoneController.text}',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Privacy & Consent Settings Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alert Consent & Privacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Control what notifications are shared with your caregiver.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Share Low-Confidence Scan Alerts'),
                        subtitle: const Text('Notify when scan fails 2 times'),
                        value: _shareScanAlerts,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (val) => setState(() => _shareScanAlerts = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Share Missed Dose Alerts'),
                        subtitle: const Text('Notify after 30 min grace period'),
                        value: _shareMissedDoses,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (val) => setState(() => _shareMissedDoses = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Include Strip Photo in Alert'),
                        subtitle: const Text('Default OFF for privacy. Requires explicit consent.'),
                        value: _includePhoto,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (val) => setState(() => _includePhoto = val),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Caregiver Event Log / Simulated Alerts
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Simulated Alert Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Prototype Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Prototype: simulated alert — nothing was sent externally.',
                                style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (events.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text('No caregiver escalation events recorded.', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final e = events[events.length - 1 - index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                              title: Text('${e.eventType} — ${e.medicineName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${e.note}\nTime: ${e.timestamp.toString().substring(11, 16)}'),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Simulated SOS Alert sent to Rahul (${_phoneController.text})'),
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  );
                },
                icon: const Icon(Icons.send, size: 24),
                label: const Text('SEND TEST CAREGIVER ALERT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
