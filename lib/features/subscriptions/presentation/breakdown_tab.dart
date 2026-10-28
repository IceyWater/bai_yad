import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import 'subscription_tabs.dart';

class BreakdownTab extends StatelessWidget {
  const BreakdownTab({
    required this.annualized,
    required this.categories,
    required this.total,
    required this.itemCount,
    required this.onPeriodChanged,
    super.key,
  });

  final bool annualized;
  final List<CategorySpending> categories;
  final double total;
  final int itemCount;
  final ValueChanged<bool> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final cadence = annualized ? '/yr' : '/mo';
    final roundedTotal = total.round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 25),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATEGORY BREAKDOWN',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Normalized cost distribution\nacross categories',
                    style: TextStyle(
                      color: AppColors.textSubtle,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            PeriodPill(
              firstLabel: 'Monthly',
              secondLabel: 'Annualized',
              secondSelected: annualized,
              onFirst: () => onPeriodChanged(false),
              onSecond: () => onPeriodChanged(true),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 186,
          child: Center(
            child: SizedBox(
              width: 148,
              height: 148,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(148),
                    painter: _DonutPainter(categories: categories),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPeso(roundedTotal.toDouble()),
                        key: const Key('breakdownTotalAmount'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$itemCount active items',
                        style: const TextStyle(color: AppColors.muted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Column(
            children: [
              for (var index = 0; index < categories.length; index++)
                _BreakdownCategoryRow(
                  category: categories[index],
                  percent: total <= 0
                      ? 0
                      : categories[index].amount / total * 100,
                  cadence: cadence,
                  showDivider: index != categories.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.categories});
  final List<CategorySpending> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 16.0;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final total = categories.fold<double>(0, (sum, item) => sum + item.amount);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final category in categories) {
      final sweep = category.amount / total * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = category.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories;
}

class _BreakdownCategoryRow extends StatelessWidget {
  const _BreakdownCategoryRow({
    required this.category,
    required this.percent,
    required this.cadence,
    required this.showDivider,
  });

  final CategorySpending category;
  final double percent;
  final String cadence;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 45),
    decoration: BoxDecoration(
      border: showDivider
          ? const Border(bottom: BorderSide(color: AppColors.rowDivider))
          : null,
    ),
    child: Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: category.color,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textRow,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${percent.round()}%',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ),
        Text(
          formatPeso(category.amount.roundToDouble()),
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(cadence, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
      ],
    ),
  );
}
