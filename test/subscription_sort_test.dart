import 'package:flutter_test/flutter_test.dart';
import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_category.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_sort.dart';

void main() {
  final subscriptions = [
    _subscription(
      id: 'later',
      name: 'Zulu',
      amount: 120,
      cycle: BillingCycle.monthly,
      renewal: DateTime(2026, 11, 20),
    ),
    _subscription(
      id: 'weekly',
      name: 'Alpha',
      amount: 30,
      cycle: BillingCycle.weekly,
      renewal: DateTime(2026, 10, 30),
    ),
    _subscription(
      id: 'earlier',
      name: 'Alpha',
      amount: 120,
      cycle: BillingCycle.monthly,
      renewal: DateTime(2026, 10, 30),
    ),
  ];

  test('sorts by next renewal with stable name and ID ties', () {
    expect(
      sortSubscriptions(
        subscriptions,
        SubscriptionSort.nextRenewal,
        from: DateTime(2026, 10, 29),
      ).map((entry) => entry.id),
      ['earlier', 'weekly', 'later'],
    );
  });

  test('sorts price by normalized monthly commitment', () {
    expect(
      sortSubscriptions(subscriptions, SubscriptionSort.price)
          .map((entry) => entry.id),
        ['earlier', 'later', 'weekly'],
    );
  });

  test('sorts names case-insensitively and uses IDs for duplicate names', () {
    expect(
      sortSubscriptions(subscriptions, SubscriptionSort.name)
          .map((entry) => entry.id),
      ['earlier', 'weekly', 'later'],
    );
  });
}

Subscription _subscription({
  required String id,
  required String name,
  required double amount,
  required BillingCycle cycle,
  required DateTime renewal,
}) => Subscription(
  id: id,
  name: name,
  amount: amount,
  billingCycle: cycle,
  category: SubscriptionCategory.streaming,
  anchorDate: renewal,
  createdAt: DateTime(2026, 1, 1),
);