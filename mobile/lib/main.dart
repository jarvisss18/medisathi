import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service and request permissions on startup.
  await NotificationService().init();

  // When user taps a system notification, open the Reminders screen.
  NotificationService.onNotificationTap = (payload) {
    appRouter.go('/reminders');
  };

  runApp(
    const ProviderScope(
      child: MediSathiApp(),
    ),
  );
}

class MediSathiApp extends StatelessWidget {
  const MediSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MediSathi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('hi', ''),
        Locale('mr', ''),
      ],
    );
  }
}
