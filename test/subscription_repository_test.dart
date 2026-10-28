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
}
