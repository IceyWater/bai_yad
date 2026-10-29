import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/name_initials.dart';
import '../subscriptions/application/subscription_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, required this.destinationBuilder});

  /// Builds the next screen with the profile name, without coupling this
  /// screen to a specific destination widget.
  final Widget Function(String name) destinationBuilder;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();

  Future<void> _continue({bool anonymous = false}) async {
    final name = anonymous || _nameController.text.trim().isEmpty
        ? 'Anonymous'
        : _nameController.text.trim();
    try {
      await ref.read(profileControllerProvider.notifier).save(name);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save your profile: $error')),
      );
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => widget.destinationBuilder(name)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SetupPill(),
                      const SizedBox(height: 18),
                      const Text(
                        'What should we\ncall you?',
                        style: TextStyle(
                          fontSize: 29,
                          height: 1.17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'BAI-yad customizes your smart insights locally. Your name never leaves this phone.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      AnimatedBuilder(
                        animation: _nameController,
                        builder: (context, _) => _Avatar(
                          initials: nameInitials(
                            _nameController.text,
                            emptyValue: '?',
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Text(
                            'YOUR FULL OR FIRST NAME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'REQUIRED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brightGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: TextField(
                          key: const Key('profileNameInput'),
                          controller: _nameController,
                          maxLength: 32,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'e.g. Alex Morgan',
                            hintStyle: const TextStyle(
                              color: AppColors.textMuted,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              key: const Key('clearNameButton'),
                              tooltip: 'Clear name',
                              onPressed: _nameController.clear,
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          key: const Key('getStartedButton'),
                          onPressed: () => _continue(),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                          label: const Text('Get started'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brightGreen,
                            foregroundColor: AppColors.onBrightGreen,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('skipButton'),
                        onPressed: () => _continue(anonymous: true),
                        child: const Center(
                          child: Text(
                            'Skip for now, stay anonymous',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SetupPill extends StatelessWidget {
  const _SetupPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.green.withValues(alpha: 0.12),
      border: Border.all(color: AppColors.green.withValues(alpha: 0.28)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: AppColors.brightGreen),
        SizedBox(width: 7),
        Text(
          'QUICK SETUP',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.brightGreen,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    height: 104,
    padding: const EdgeInsets.all(2),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [AppColors.green, AppColors.brandDeep]),
    ),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ink,
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: AppColors.brightGreen,
          ),
        ),
      ),
    ),
  );
}
