import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/verification/verification_result_screen.dart';
import '../features/medicine_details/medicine_details_screen.dart';
import '../features/interactions/interaction_screen.dart';
import '../features/reminders/set_reminder_screen.dart';
import '../features/reminders/reminders_list_screen.dart';
import '../features/my_medicines/my_medicines_screen.dart';
import '../features/caregiver/caregiver_screen.dart';
import '../features/settings/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/verification',
      builder: (context, state) => const VerificationResultScreen(),
    ),
    GoRoute(
      path: '/details',
      builder: (context, state) => const MedicineDetailsScreen(),
    ),
    GoRoute(
      path: '/interaction',
      builder: (context, state) => const InteractionScreen(),
    ),
    GoRoute(
      path: '/set-reminder',
      builder: (context, state) => const SetReminderScreen(),
    ),
    GoRoute(
      path: '/my-medicines',
      builder: (context, state) => const MyMedicinesScreen(),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const RemindersListScreen(),
    ),
    GoRoute(
      path: '/caregiver',
      builder: (context, state) => const CaregiverScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
