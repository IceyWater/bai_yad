import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.green,
          onPrimary: AppColors.ink,
          surface: AppColors.panel,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.muted,
          outline: AppColors.line,
          error: AppColors.danger,
        );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.ink,
      dividerColor: AppColors.line,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.textPrimary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.panel,
        modalBackgroundColor: AppColors.panel,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.panelRaised,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
