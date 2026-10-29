import 'subscription.dart';
import 'billing_cycle.dart';

class UpcomingRenewal {
  const UpcomingRenewal({required this.subscription, required this.date});

  final Subscription subscription;
  final DateTime date;
}

DateTime nextRenewal(DateTime anchor, BillingCycle cycle, {DateTime? from}) {
  final target = _dateOnly(from ?? DateTime.now());
  final anchorDate = _dateOnly(anchor);

  if (cycle == BillingCycle.weekly) {
    final daysFromAnchor = target.difference(anchorDate).inDays;
    final weeks = daysFromAnchor <= 0 ? 0 : (daysFromAnchor + 6) ~/ 7;
    return DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day + weeks * 7,
    );
  }

  final interval = cycle.monthInterval!;
  final anchorMonth = anchorDate.year * 12 + anchorDate.month - 1;
  final targetMonth = target.year * 12 + target.month - 1;
  final monthDifference = targetMonth - anchorMonth;
  var intervals = monthDifference <= 0
      ? 0
      : (monthDifference + interval - 1) ~/ interval;
  var candidate = _monthOccurrence(anchorDate, interval * intervals);
  if (candidate.isBefore(target)) {
    intervals++;
    candidate = _monthOccurrence(anchorDate, interval * intervals);
  }
  return candidate;
}

List<UpcomingRenewal> upcomingRenewals(
  Iterable<Subscription> subscriptions, {
  DateTime? from,
  int? limit,
}) {
  if (limit != null && limit <= 0) return const [];
  final renewals =
      subscriptions
          .map(
            (subscription) => UpcomingRenewal(
              subscription: subscription,
              date: nextRenewal(
                subscription.anchorDate,
                subscription.billingCycle,
                from: from,
              ),
            ),
          )
          .toList()
        ..sort((first, second) {
          final byDate = first.date.compareTo(second.date);
          return byDate != 0
              ? byDate
              : first.subscription.name.compareTo(second.subscription.name);
        });
  return limit == null ? renewals : renewals.take(limit).toList();
}

String renewalLabel(DateTime renewal, {DateTime? today}) {
  final currentDate = _dateOnly(today ?? DateTime.now());
  final renewalDate = _dateOnly(renewal);
  final days = renewalDate.difference(currentDate).inDays;
  return switch (days) {
    < 0 => 'Overdue',
    0 => 'Today',
    1 => 'Tomorrow',
    _ => 'In $days days',
  };
}

DateTime _monthOccurrence(DateTime anchor, int monthOffset) {
  final monthIndex = anchor.year * 12 + anchor.month - 1 + monthOffset;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, anchor.day.clamp(1, lastDay));
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
