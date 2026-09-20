import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_providers.dart';

class CaregiverScreen extends ConsumerStatefulWidget {
  const CaregiverScreen({super.key});

  @override
  ConsumerState<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends ConsumerState<CaregiverScreen> {
  final _nameController = TextEditingController(text: 'Rahul Patil');
  final _phoneController = TextEditingController(text: '+919820012345');
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

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $cleanPhone...')),
        );
      }
    }
  }

  Future<void> _sendSms(String phone, String message) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: {'body': message},
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sending SMS to $cleanPhone...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicineRepositoryProvider);
    final events = repo.caregiverEvents;

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
          title: const Text('Caregiver Contact & Alerts'),
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
                              child: const Icon(Icons.contact_phone, color: Color(0xFF1E6FE8), size: 32),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Primary Caregiver', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                  Text('Rahul Patil (Son)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Caregiver Name', prefixIcon: Icon(Icons.person)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _relationController,
                          decoration: const InputDecoration(labelText: 'Relationship', prefixIcon: Icon(Icons.family_restroom)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                onPressed: () => _makePhoneCall(_phoneController.text),
                                icon: const Icon(Icons.call),
                                label: const Text('Call Now'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E6FE8)),
                                onPressed: () => _sendSms(
                                  _phoneController.text,
                                  'MediSathi Alert from Mrs. Sunanda: I need assistance verifying my medicine.',
                                ),
                                icon: const Icon(Icons.message),
                                label: const Text('Send SMS'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Alert Escalation Settings Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Automatic Alert Triggers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Alert on Repeated Scan Failures'),
                          subtitle: const Text('Auto-triggers when 2 scans fail quality check'),
                          value: _shareScanAlerts,
                          onChanged: (val) => setState(() => _shareScanAlerts = val),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Alert on Missed Doses'),
                          subtitle: const Text('Triggers if dose is unconfirmed after 30 mins'),
                          value: _shareMissedDoses,
                          onChanged: (val) => setState(() => _shareMissedDoses = val),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Attach Strip Photo in Message'),
                          subtitle: const Text('Sends picture of unverified strip'),
                          value: _includePhoto,
                          onChanged: (val) => setState(() => _includePhoto = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Caregiver Alert History Log Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Caregiver Alert History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Active Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                            ),
                          ],
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
                    _sendSms(
                      _phoneController.text,
                      '🚨 MEDISATHI SOS EMERGENCY ALERT: Mrs. Sunanda Patil requires immediate medication review assistance.',
                    );
                  },
                  icon: const Icon(Icons.send, size: 24),
                  label: const Text('SEND CAREGIVER SOS SMS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
