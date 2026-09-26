import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _pinInput = '';
  final _phoneController = TextEditingController(text: '+91 98200 98765');
  final _otpController = TextEditingController(text: '9876');
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    if (_pinInput.length < 4) {
      setState(() {
        _pinInput += value;
        _errorMessage = null;
      });
      if (_pinInput.length == 4) {
        _handlePinSubmit();
      }
    }
  }

  void _onKeypadBackspace() {
    if (_pinInput.isNotEmpty) {
      setState(() {
        _pinInput = _pinInput.substring(0, _pinInput.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _handlePinSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authRepositoryProvider).loginWithPin(_pinInput);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/home');
      } else {
        setState(() {
          _pinInput = '';
          _errorMessage = 'Incorrect PIN code. Try default 1234.';
        });
      }
    }
  }

  Future<void> _handleOtpSubmit() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authRepositoryProvider).loginWithPhoneAndOtp(phone, otp);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/home');
      } else {
        setState(() => _errorMessage = 'Invalid OTP code. Please enter 9876');
      }
    }
  }

  Future<void> _handleGuestAccess() async {
    await ref.read(authRepositoryProvider).loginAsGuest();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // App Logo Header
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E6FE8).withValues(alpha: 0.3), width: 2),
                        ),
                        child: const Icon(Icons.security, size: 44, color: Color(0xFF1E6FE8)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'MediSathi',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Elderly-Friendly Medication Security',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation Tabs
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF1E6FE8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF475569),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: '4-Digit PIN'),
                      Tab(text: 'Phone OTP'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Error Message SnackBar Box
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(
                  height: 310,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPinView(),
                      _buildOtpView(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Emergency Guest Access Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF10B981), width: 1.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _handleGuestAccess,
                  icon: const Icon(Icons.flash_on, color: Color(0xFF10B981)),
                  label: const Text(
                    'EMERGENCY SCAN ACCESS (GUEST)',
                    style: TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),

                const SizedBox(height: 12),

                // New User Registration Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have a profile?", style: TextStyle(color: Color(0xFF64748B))),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text(
                        'Register Profile',
                        style: TextStyle(color: Color(0xFF1E6FE8), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter Your 4-Digit Security PIN',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 12),
        // PIN Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final isFilled = index < _pinInput.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? const Color(0xFF1E6FE8) : const Color(0xFFCBD5E1),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        // Numeric Keypad Grid
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['C', '0', '⌫']
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () {
                        if (key == 'C') {
                          setState(() => _pinInput = '');
                        } else if (key == '⌫') {
                          _onKeypadBackspace();
                        } else {
                          _onKeypadTap(key);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: key == '⌫' || key == 'C' ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildOtpView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Mobile Phone Number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        if (!_otpSent)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6FE8),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              setState(() {
                _otpSent = true;
                _errorMessage = null;
              });
            },
            icon: const Icon(Icons.send),
            label: const Text('SEND 4-DIGIT OTP CODE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('Demo OTP code sent to your phone: 9876', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              labelText: 'Enter 4-Digit Verification Code',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isLoading ? null : _handleOtpSubmit,
            icon: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.verified_user),
            label: const Text('VERIFY & LOGIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ],
    );
  }
}
