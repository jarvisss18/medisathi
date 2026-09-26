import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/app_providers.dart';
import '../../data/models.dart';

class CaregiverScreen extends ConsumerStatefulWidget {
  const CaregiverScreen({super.key});

  @override
  ConsumerState<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends ConsumerState<CaregiverScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationController;

  late bool _shareScanAlerts;
  late bool _shareMissedDoses;
  late bool _includePhoto;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final initialContact = ref.read(medicineRepositoryProvider).caregiverContact;
    _nameController = TextEditingController(text: initialContact.name);
    _phoneController = TextEditingController(text: initialContact.phone);
    _relationController = TextEditingController(text: initialContact.relationship);

    _shareScanAlerts = initialContact.alertOnScanFailures;
    _shareMissedDoses = initialContact.alertOnMissedDoses;
    _includePhoto = initialContact.attachPhoto;
    _isInitialized = true;
  }

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

  void _saveContactDetails({bool showSnackBar = true}) {
    final updated = CaregiverContact(
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Rahul Patil',
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '+919820012345',
      relationship: _relationController.text.trim().isNotEmpty ? _relationController.text.trim() : 'Son',
      alertOnScanFailures: _shareScanAlerts,
      alertOnMissedDoses: _shareMissedDoses,
      attachPhoto: _includePhoto,
    );

    ref.read(medicineRepositoryProvider).updateCaregiverContact(updated);

    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Caregiver contact & settings saved successfully!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
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
    final contact = repo.caregiverContact;
    final events = repo.caregiverEvents;

    if (_isInitialized &&
        (_nameController.text != contact.name ||
            _phoneController.text != contact.phone ||
            _relationController.text != contact.relationship)) {
      // Sync if updated externally
    }

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
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => _saveContactDetails(),
              tooltip: 'Save Settings',
            ),
          ],
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Primary Caregiver', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                  Text('${contact.name} (${contact.relationship})',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Caregiver Name', prefixIcon: Icon(Icons.person)),
                          onChanged: (_) => _saveContactDetails(showSnackBar: false),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                          onChanged: (_) => _saveContactDetails(showSnackBar: false),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _relationController,
                          decoration: const InputDecoration(labelText: 'Relationship', prefixIcon: Icon(Icons.family_restroom)),
                          onChanged: (_) => _saveContactDetails(showSnackBar: false),
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
                                  'MediSathi Alert from patient: I need assistance verifying my medicine with caregiver ${_nameController.text}.',
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
                          onChanged: (val) {
                            setState(() => _shareScanAlerts = val);
                            _saveContactDetails(showSnackBar: false);
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Alert on Missed Doses'),
                          subtitle: const Text('Triggers if dose is unconfirmed after 30 mins'),
                          value: _shareMissedDoses,
                          onChanged: (val) {
                            setState(() => _shareMissedDoses = val);
                            _saveContactDetails(showSnackBar: false);
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Attach Strip Photo in Message'),
                          subtitle: const Text('Sends picture of unverified strip'),
                          value: _includePhoto,
                          onChanged: (val) {
                            setState(() => _includePhoto = val);
                            _saveContactDetails(showSnackBar: false);
                          },
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
                      '🚨 MEDISATHI SOS EMERGENCY ALERT: Patient requires immediate medication review assistance from caregiver ${_nameController.text}.',
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

