import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bai_yad/features/subscriptions/data/shared_preferences_subscription_repository.dart';
import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_category.dart';

void main() {
  late SharedPreferencesSubscriptionRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SharedPreferencesSubscriptionRepository();
  });

  test('missing subscription data loads as an empty collection', () async {
    expect(await repository.loadSubscriptions(), isEmpty);
  });

  test(
    'subscriptions and profile name round-trip through local storage',
    () async {
      final subscription = Subscription(
        id: 'netflix',
        name: 'Netflix',
        amount: 549,
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.streaming,
        anchorDate: DateTime(2026, 10, 23),
        createdAt: DateTime(2026, 1, 1),
      );

      await repository.saveSubscriptions([subscription]);
      await repository.saveProfileName('Alex');

      expect(await repository.loadSubscriptions(), [subscription]);
      expect(await repository.loadProfileName(), 'Alex');
    },
  );

  test('corrupt subscription JSON is reported for explicit recovery', () async {
    SharedPreferences.setMockInitialValues({'subscriptions.v1': '{broken'});

    await expectLater(
      repository.loadSubscriptions(),
      throwsA(isA<CorruptSubscriptionDataException>()),
    );
  });

  test('loads previously saved numeric amount values', () async {
    SharedPreferences.setMockInitialValues({
      'subscriptions.v1': jsonEncode([
        {
          'id': 'legacy',
          'name': 'Legacy plan',
          'amount': 1299.99,
          'billingCycle': 'monthly',
          'category': 'streaming',
          'anchorDate': '2026-10-23T00:00:00.000',
          'createdAt': '2026-01-01T00:00:00.000',
        },
      ]),
    });

    final loaded = await repository.loadSubscriptions();

    expect(loaded.single.amount, 1299.99);
  });
}
