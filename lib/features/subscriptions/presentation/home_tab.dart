import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../domain/billing_cycle.dart';
import '../domain/cost_calculator.dart';
import '../domain/renewal_calculator.dart';
import '../domain/subscription.dart';
import 'subscription_presentation.dart';
import 'subscription_tabs.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    required this.subscriptions,
    required this.rarelyUsedSubscriptions,
    required this.renewals,
    required this.monthlyTotal,
    required this.annualTotal,
    required this.monthlyCategories,
    required this.yearly,
    required this.onYearlyChanged,
    required this.onMarkUsed,
    required this.onDelete,
    this.deleteNoticeVisible = false,
    super.key,
  });

  final List<Subscription> subscriptions;
  final List<Subscription> rarelyUsedSubscriptions;
  final List<UpcomingRenewal> renewals;
  final double monthlyTotal;
  final double annualTotal;
  final List<CategorySpending> monthlyCategories;
  final bool yearly;
  final ValueChanged<bool> onYearlyChanged;
  final ValueChanged<Subscription> onMarkUsed;
  final ValueChanged<Subscription> onDelete;
  final bool deleteNoticeVisible;

  @override
  Widget build(BuildContext context) {
    final total = yearly ? annualTotal : monthlyTotal;
    final formattedTotal = formatPeso(total);
    final currencyIndex = formattedTotal.indexOf('₱');
    final cadence = yearly ? '/yr' : '/mo';
    final categories = monthlyCategories
        .where((item) => item.amount > 0)
        .toList();
    final categoryTotal = categories.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(12, 17, 12, deleteNoticeVisible ? 96 : 25),
      children: [
        const Text(
          'TOTAL COMMITMENT',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: formattedTotal.substring(0, currencyIndex),
                          ),
                          const TextSpan(
                            text: '₱',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: formattedTotal.substring(currencyIndex + 1),
                          ),
                        ],
                        style: const TextStyle(
                          fontSize: 30,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      key: const Key('homeTotalAmount'),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      cadence,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PeriodPill(
          surfaceKey: const Key('homePeriodSelector'),
          firstLabel: 'Monthly',
          secondLabel: 'Yearly',
          secondDetail: formatPeso(annualTotal.roundToDouble()),
          secondSelected: yearly,
          onFirst: () => onYearlyChanged(false),
          onSecond: () => onYearlyChanged(true),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              for (final category in categories)
                Expanded(
                  flex: math.max(
                    6,
                    (category.amount /
                            (categoryTotal == 0 ? 1 : categoryTotal) *
                            100)
                        .round(),
                  ),
                  child: ColoredBox(
                    color: category.color,
                    child: const SizedBox(height: 4),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            for (final category in categories)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _CategoryLegend(
                    category: category,
                    percent: categoryTotal == 0
                        ? 0
                        : category.amount / categoryTotal * 100,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 19),
        if (rarelyUsedSubscriptions.isNotEmpty) ...[
          _RarelyUsedSubscriptions(
            subscriptions: rarelyUsedSubscriptions,
            onMarkUsed: onMarkUsed,
          ),
          const SizedBox(height: 18),
        ],
        const Text(
          'UPCOMING RENEWALS',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        for (final renewal in renewals)
          _HomeRenewalRow(
            renewal: renewal,
            onDelete: () => onDelete(renewal.subscription),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 13),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 13, color: AppColors.brightGreen),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Your financial data stays on this device',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({required this.category, required this.percent});
  final CategorySpending category;
  final double percent;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: category.color,
        ),
      ),
      const SizedBox(width: 4),
      Text(
        '${_shortCategory(category.name)} ${percent.round()}%',
        style: const TextStyle(color: AppColors.textSoft, fontSize: 10),
      ),
    ],
  );
}

String _shortCategory(String category) => switch (category) {
  'Utilities & Fiber' => 'Utilities',
  'Software & Cloud' => 'Software',
  'Streaming & Media' => 'Media',
  _ => 'Work',
};

class _RarelyUsedSubscriptions extends StatelessWidget {
  const _RarelyUsedSubscriptions({
    required this.subscriptions,
    required this.onMarkUsed,
  });

  final List<Subscription> subscriptions;
  final ValueChanged<Subscription> onMarkUsed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.warningAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 15,
                color: AppColors.warningAccent,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'RARELY USED',
                style: TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final subscription in subscriptions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${subscription.name} · ${formatPeso(monthlyCost(subscription))}/mo potential',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onMarkUsed(subscription),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brightGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(48, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark as used',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _HomeRenewalRow extends StatelessWidget {
  const _HomeRenewalRow({required this.renewal, required this.onDelete});
  final UpcomingRenewal renewal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final entry = renewal.subscription;
    final due = renewalLabel(renewal.date);
    final overdue = due == 'Overdue';
    final dueColor = overdue ? AppColors.danger : AppColors.brightGreen;
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.subtleBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: entry.color.withValues(alpha: 0.25)),
            ),
            child: Icon(entry.icon, size: 20, color: entry.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.billingCycle.label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
                const SizedBox(height: 3),
                Text(
                  due,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: dueColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 58,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                entry.amountLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove ${entry.name}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: EdgeInsets.zero,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 17,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
