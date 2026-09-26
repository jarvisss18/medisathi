import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController(text: 'Mrs. Sunanda Patil');
  final _phoneController = TextEditingController(text: '+91 98200 98765');
  final _pinController = TextEditingController(text: '1234');
  String _role = 'Patient';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (name.isEmpty || phone.isEmpty || pin.length < 4) {
      setState(() => _error = 'Please enter valid name, phone, and 4-digit PIN.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authRepositoryProvider).registerUser(
          name: name,
          phone: phone,
          pin: pin,
          role: _role,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Profile created for $name!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create User Profile'),
        backgroundColor: const Color(0xFF1E6FE8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.person_add_alt_1, size: 64, color: Color(0xFF1E6FE8)),
            const SizedBox(height: 12),
            const Text(
              'Set Up Your Profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Quick setup for elderly medication tracking and caregiver escalation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),

            const SizedBox(height: 24),

            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold)),
              ),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number *',
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Set 4-Digit Lock PIN *',
                        prefixIcon: Icon(Icons.lock_clock),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: const InputDecoration(
                        labelText: 'User Role',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Patient', child: Text('Patient (Self)')),
                        DropdownMenuItem(value: 'Caregiver', child: Text('Caregiver / Guardian')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _role = val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : _handleRegister,
              icon: const Icon(Icons.check_circle, size: 24),
              label: const Text('CREATE PROFILE & SIGN IN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
