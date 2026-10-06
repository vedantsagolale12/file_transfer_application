import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light theme
  static const Color lightPrimary = Color(0xFF1565C0);
  static const Color lightPrimaryContainer = Color(0xFFD6E4FF);
  static const Color lightSecondary = Color(0xFF0277BD);
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F5);
  static const Color lightError = Color(0xFFD32F2F);
  static const Color lightSuccess = Color(0xFF388E3C);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnBackground = Color(0xFF1A1A2E);
  static const Color lightOnSurface = Color(0xFF1A1A2E);

  // Dark theme
  static const Color darkPrimary = Color(0xFF4FC3F7);
  static const Color darkPrimaryContainer = Color(0xFF1A3A5C);
  static const Color darkSecondary = Color(0xFF81D4FA);
  static const Color darkBackground = Color(0xFF0D1B2A);
  static const Color darkSurface = Color(0xFF1A2B3C);
  static const Color darkSurfaceVariant = Color(0xFF243447);
  static const Color darkError = Color(0xFFEF5350);
  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkOnPrimary = Color(0xFF0D1B2A);
  static const Color darkOnBackground = Color(0xFFE8F4FD);
  static const Color darkOnSurface = Color(0xFFE8F4FD);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
  static BorderRadius get extraLarge => BorderRadius.circular(xl);
}
