import 'package:flutter/material.dart';

class RemindersListScreen extends StatelessWidget {
  const RemindersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: const Center(
        child: Text('Reminders List Screen'),
      ),
    );
  }
}
