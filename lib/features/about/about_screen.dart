import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondaryColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            AppStrings.appName,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.appSubtitle,
            style: textTheme.titleMedium?.copyWith(color: secondaryColor),
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.tagline,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.brightGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            AppStrings.aboutParagraph1,
            style: textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.aboutParagraph2,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
