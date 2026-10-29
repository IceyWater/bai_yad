import 'subscription.dart';
import 'renewal_calculator.dart';

const supportedReminderLeadTimes = [1, 3, 7];
const maxPendingReminders = 60;

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.subscription,
    required this.renewalDate,
    required this.notifyAt,
  });

  final int id;
  final Subscription subscription;
  final DateTime renewalDate;
  final DateTime notifyAt;
}

List<PlannedReminder> buildReminderPlan(
  Iterable<Subscription> subscriptions, {
  required DateTime now,
  required int daysBefore,
  int limit = maxPendingReminders,
}) {
  if (!supportedReminderLeadTimes.contains(daysBefore)) {
    throw ArgumentError.value(daysBefore, 'daysBefore');
  }
  if (limit <= 0) return const [];

  final today = DateTime(now.year, now.month, now.day);
  final firstRenewalDay = DateTime(
    today.year,
    today.month,
    today.day + daysBefore,
  );
  final reminders = <PlannedReminder>[];

  for (final subscription in subscriptions) {
    var renewalDate = nextRenewal(
      subscription.anchorDate,
      subscription.billingCycle,
      from: firstRenewalDay,
    );
    for (var index = 0; index < limit; index++) {
      final notifyAt = DateTime(
        renewalDate.year,
        renewalDate.month,
        renewalDate.day - daysBefore,
        9,
      );
      if (notifyAt.isAfter(now)) {
        reminders.add(
          PlannedReminder(
            id: _notificationId(subscription.id, renewalDate),
            subscription: subscription,
            renewalDate: renewalDate,
            notifyAt: notifyAt,
          ),
        );
      }
      renewalDate = nextRenewal(
        subscription.anchorDate,
        subscription.billingCycle,
        from: DateTime(
          renewalDate.year,
          renewalDate.month,
          renewalDate.day + 1,
        ),
      );
    }
  }

  reminders.sort((first, second) {
    final byTime = first.notifyAt.compareTo(second.notifyAt);
    if (byTime != 0) return byTime;
    final byName = first.subscription.name.compareTo(second.subscription.name);
    return byName != 0 ? byName : first.id.compareTo(second.id);
  });
  return reminders.take(limit).toList(growable: false);
}

int _notificationId(String subscriptionId, DateTime renewalDate) {
  final value =
      '$subscriptionId:${renewalDate.year}-${renewalDate.month}-${renewalDate.day}';
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
  }
  return hash;
}
