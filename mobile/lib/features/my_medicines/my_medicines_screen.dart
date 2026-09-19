import 'package:flutter/material.dart';

class MyMedicinesScreen extends StatelessWidget {
  const MyMedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: const Center(
        child: Text('My Medicines List Screen'),
      ),
    );
  }
}
