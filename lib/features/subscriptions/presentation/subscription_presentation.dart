import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../domain/billing_cycle.dart';
import '../domain/subscription.dart';
import '../domain/subscription_category.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatSubscriptionDate(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

extension SubscriptionPresentation on Subscription {
  IconData get icon => switch (category) {
    SubscriptionCategory.utilities => Icons.wifi_rounded,
    SubscriptionCategory.streaming => Icons.movie_outlined,
    SubscriptionCategory.software => Icons.draw_outlined,
    SubscriptionCategory.workTools => Icons.cloud_outlined,
    SubscriptionCategory.productivity => Icons.checklist_rounded,
  };

  Color get color => Color(colorArgb ?? AppColors.mint.toARGB32());

  String get cadence => switch (billingCycle) {
    BillingCycle.weekly => '/wk',
    BillingCycle.monthly => '/mo',
    BillingCycle.quarterly => '/qtr',
    BillingCycle.biAnnual => '/6 mo',
    BillingCycle.yearly => '/yr',
  };

  String get dateLabel => formatSubscriptionDate(anchorDate);

  String get amountLabel => formatPeso(amount);
}

