import 'package:flutter/material.dart';

class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver Settings & Alerts')),
      body: const Center(
        child: Text('Caregiver Alert Screen'),
      ),
    );
  }
}
