import 'package:flutter_test/flutter_test.dart';

import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/reminder_schedule.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_category.dart';

void main() {
  test('plans lead-time reminders from the original monthly anchor', () {
    final subscription = _subscription(
      id: 'monthly',
      anchorDate: DateTime(2026, 1, 31),
      billingCycle: BillingCycle.monthly,
    );

    final plan = buildReminderPlan(
      [subscription],
      now: DateTime(2026, 2, 1, 8),
      daysBefore: 3,
      limit: 2,
    );

    expect(plan.map((item) => item.renewalDate), [
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
    ]);
    expect(plan.first.notifyAt, DateTime(2026, 2, 25, 9));
    expect(
      buildReminderPlan(
        [subscription],
        now: DateTime(2026, 2, 1, 8),
        daysBefore: 3,
        limit: 2,
      ).first.id,
      plan.first.id,
    );
  });

  test(
    'skips notification times already passed and supports each lead time',
    () {
      final subscription = _subscription(
        id: 'weekly',
        anchorDate: DateTime(2026, 10, 29),
        billingCycle: BillingCycle.weekly,
      );

      final plan = buildReminderPlan(
        [subscription],
        now: DateTime(2026, 10, 29, 10),
        daysBefore: 1,
        limit: 1,
      );

      expect(plan.single.renewalDate, DateTime(2026, 11, 5));
      expect(plan.single.notifyAt, DateTime(2026, 11, 4, 9));
      expect(
        () => buildReminderPlan(
          [subscription],
          now: DateTime(2026, 10, 29),
          daysBefore: 2,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'bounds the plan and sorts simultaneous reminders deterministically',
    () {
      final subscriptions = [
        _subscription(
          id: 'z',
          name: 'Zeta',
          anchorDate: DateTime(2026, 11, 10),
        ),
        _subscription(
          id: 'a',
          name: 'Alpha',
          anchorDate: DateTime(2026, 11, 10),
        ),
      ];

      final plan = buildReminderPlan(
        subscriptions,
        now: DateTime(2026, 10, 29),
        daysBefore: 1,
        limit: 1,
      );

      expect(plan, hasLength(1));
      expect(plan.single.subscription.name, 'Alpha');
    },
  );

  test('schedules at 9 a.m. but skips when that reminder time has passed', () {
    final subscription = _subscription(
      id: 'boundary',
      anchorDate: DateTime(2026, 10, 30),
      billingCycle: BillingCycle.weekly,
    );

    final beforeReminderTime = buildReminderPlan(
      [subscription],
      now: DateTime(2026, 10, 29, 8, 59),
      daysBefore: 1,
      limit: 1,
    );
    final atReminderTime = buildReminderPlan(
      [subscription],
      now: DateTime(2026, 10, 29, 9),
      daysBefore: 1,
      limit: 1,
    );

    expect(beforeReminderTime.single.notifyAt, DateTime(2026, 10, 29, 9));
    expect(atReminderTime, isEmpty);
  });
}

Subscription _subscription({
  required String id,
  String? name,
  required DateTime anchorDate,
  BillingCycle billingCycle = BillingCycle.monthly,
}) => Subscription(
  id: id,
  name: name ?? id,
  amount: 100,
  billingCycle: billingCycle,
  category: SubscriptionCategory.software,
  anchorDate: anchorDate,
  createdAt: DateTime(2026, 1, 1),
);
