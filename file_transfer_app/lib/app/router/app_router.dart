import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_transfer_app/features/connection/presentation/pages/discovery_page.dart';
import 'package:file_transfer_app/features/connection/presentation/pages/manual_connect_page.dart';
import 'package:file_transfer_app/features/connection/presentation/pages/home_page.dart';
import 'package:file_transfer_app/features/files/presentation/pages/files_page.dart';
import 'package:file_transfer_app/features/transfer/presentation/pages/transfers_page.dart';
import 'package:file_transfer_app/features/settings/presentation/pages/settings_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String discovery = '/discovery';
  static const String manualConnect = '/manual-connect';
  static const String home = '/home';
  static const String files = '/files';
  static const String transfers = '/transfers';
  static const String settings = '/settings';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.discovery,
  routes: [
    GoRoute(
      path: AppRoutes.discovery,
      builder: (context, state) => const DiscoveryPage(),
    ),
    GoRoute(
      path: AppRoutes.manualConnect,
      builder: (context, state) => const ManualConnectPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'files',
          builder: (context, state) => const FilesPage(),
        ),
        GoRoute(
          path: 'transfers',
          builder: (context, state) => const TransfersPage(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
