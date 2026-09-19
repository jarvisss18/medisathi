import 'package:flutter/material.dart';

class MedicineDetailsScreen extends StatelessWidget {
  const MedicineDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Details')),
      body: const Center(
        child: Text('Medicine Details Screen'),
      ),
    );
  }
}
