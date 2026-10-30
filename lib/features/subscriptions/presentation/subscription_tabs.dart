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
    this.secondDetail,
    required this.secondSelected,
    required this.onFirst,
    required this.onSecond,
    this.surfaceKey,
    super.key,
  });

  final String firstLabel;
  final String secondLabel;
  final String? secondDetail;
  final bool secondSelected;
  final VoidCallback onFirst;
  final VoidCallback onSecond;
  final Key? surfaceKey;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    widthFactor: 1,
    child: DecoratedBox(
      key: surfaceKey,
      decoration: BoxDecoration(
        color: AppColors.toggleSurface,
        border: Border.all(color: AppColors.toggleBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PeriodPillButton(
              buttonKey: const Key('monthlyPeriodButton'),
              label: firstLabel,
              selected: !secondSelected,
              onTap: onFirst,
            ),
            _PeriodPillButton(
              buttonKey: const Key('annualPeriodButton'),
              label: secondLabel,
              detail: secondDetail,
              selected: secondSelected,
              onTap: onSecond,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PeriodPillButton extends StatelessWidget {
  const _PeriodPillButton({
    required this.buttonKey,
    required this.label,
    this.detail,
    required this.selected,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    child: Semantics(
      button: true,
      child: InkWell(
        key: buttonKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? AppColors.selectedControl : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: detail == null
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 55),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSoft,
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 95),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: label),
                          TextSpan(
                            text: ' ($detail)',
                            style: const TextStyle(color: AppColors.textSoft),
                          ),
                        ],
                        style: TextStyle(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSoft,
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}
