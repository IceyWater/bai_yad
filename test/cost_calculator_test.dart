import 'package:flutter_test/flutter_test.dart';
import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/cost_calculator.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_category.dart';

void main() {
  Subscription entry(BillingCycle cycle, double amount) => Subscription(
    id: 'test',
    name: 'Test subscription',
    amount: amount,
    billingCycle: cycle,
    category: SubscriptionCategory.streaming,
    anchorDate: DateTime(2026, 1, 31),
    createdAt: DateTime(2026, 1, 1),
  );

  test('normalizes each billing cycle to monthly and annual costs', () {
    expect(
      monthlyCost(entry(BillingCycle.weekly, 100)),
      closeTo(433.333, 0.001),
    );
    expect(annualCost(entry(BillingCycle.weekly, 100)), 5200);
    expect(monthlyCost(entry(BillingCycle.monthly, 120)), 120);
    expect(annualCost(entry(BillingCycle.monthly, 120)), 1440);
    expect(monthlyCost(entry(BillingCycle.quarterly, 300)), 100);
    expect(annualCost(entry(BillingCycle.quarterly, 300)), 1200);
    expect(monthlyCost(entry(BillingCycle.biAnnual, 600)), 100);
    expect(annualCost(entry(BillingCycle.biAnnual, 600)), 1200);
    expect(monthlyCost(entry(BillingCycle.yearly, 1200)), 100);
    expect(annualCost(entry(BillingCycle.yearly, 1200)), 1200);
  });

  test('serializes and copies typed subscription data', () {
    final original = entry(BillingCycle.yearly, 1200).copyWith(notes: 'Annual');
    final decoded = Subscription.fromJson(original.toJson());

    expect(decoded, original);
    expect(decoded.copyWith(clearNotes: true).notes, isNull);
  });
}
