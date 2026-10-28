import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CategorySpending {
  const CategorySpending({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final double amount;
  final Color color;
}

class PeriodPill extends StatelessWidget {
  const PeriodPill({
    required this.firstLabel,
    required this.secondLabel,
    required this.secondSelected,
    required this.onFirst,
    required this.onSecond,
    super.key,
  });

  final String firstLabel;
  final String secondLabel;
  final bool secondSelected;
  final VoidCallback onFirst;
  final VoidCallback onSecond;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.toggleSurface,
      border: Border.all(color: AppColors.toggleBorder),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PeriodPillButton(
          key: const Key('monthlyPeriodButton'),
          label: firstLabel,
          selected: !secondSelected,
          onTap: onFirst,
        ),
        _PeriodPillButton(
          key: const Key('annualPeriodButton'),
          label: secondLabel,
          selected: secondSelected,
          onTap: onSecond,
        ),
      ],
    ),
  );
}

class _PeriodPillButton extends StatelessWidget {
  const _PeriodPillButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: selected ? AppColors.white : AppColors.muted,
      backgroundColor: selected ? AppColors.selectedControl : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const StadiumBorder(),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}
