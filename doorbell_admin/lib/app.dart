import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/admin_router.dart';
import 'core/theme/admin_theme.dart';

/// Root widget for the DoorBell Admin app.
class DoorBellAdminApp extends ConsumerWidget {
  const DoorBellAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'DoorBell Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
    );
  }
}
