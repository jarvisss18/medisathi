import 'package:flutter/material.dart';

class SetReminderScreen extends StatelessWidget {
  const SetReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Reminder')),
      body: const Center(
        child: Text('Set Reminder Screen'),
      ),
    );
  }
}
