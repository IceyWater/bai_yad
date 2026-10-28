import 'billing_cycle.dart';
import 'subscription.dart';
import 'subscription_category.dart';

double monthlyCost(Subscription subscription) =>
    switch (subscription.billingCycle) {
      BillingCycle.weekly => subscription.amount * 52 / 12,
      BillingCycle.monthly => subscription.amount,
      BillingCycle.quarterly => subscription.amount / 3,
      BillingCycle.biAnnual => subscription.amount / 6,
      BillingCycle.yearly => subscription.amount / 12,
    };

double annualCost(Subscription subscription) =>
    switch (subscription.billingCycle) {
      BillingCycle.weekly => subscription.amount * 52,
      BillingCycle.monthly => subscription.amount * 12,
      BillingCycle.quarterly => subscription.amount * 4,
      BillingCycle.biAnnual => subscription.amount * 2,
      BillingCycle.yearly => subscription.amount,
    };

double totalMonthlyCost(Iterable<Subscription> subscriptions) =>
    subscriptions.fold(0, (total, item) => total + monthlyCost(item));

double totalAnnualCost(Iterable<Subscription> subscriptions) =>
    subscriptions.fold(0, (total, item) => total + annualCost(item));

Map<SubscriptionCategory, double> categoryCostTotals(
  Iterable<Subscription> subscriptions, {
  required bool annualized,
}) {
  final totals = <SubscriptionCategory, double>{};
  for (final subscription in subscriptions) {
    final amount = annualized
        ? annualCost(subscription)
        : monthlyCost(subscription);
    totals.update(
      subscription.category,
      (total) => total + amount,
      ifAbsent: () => amount,
    );
  }
  return totals;
}
