import 'package:flutter/material.dart';

class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Result')),
      body: const Center(
        child: Text('Verification Result Screen'),
      ),
    );
  }
}
