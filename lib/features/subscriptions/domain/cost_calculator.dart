import 'billing_cycle.dart';
import 'subscription.dart';
import 'subscription_category.dart';

double monthlyCost(Subscription subscription) =>
    switch (subscription.billingCycle) {
      BillingCycle.weekly => subscription.amountInCentavos * 52 / 1200,
      BillingCycle.monthly => subscription.amountInCentavos / 100,
      BillingCycle.quarterly => subscription.amountInCentavos / 300,
      BillingCycle.biAnnual => subscription.amountInCentavos / 600,
      BillingCycle.yearly => subscription.amountInCentavos / 1200,
    };

double annualCost(Subscription subscription) =>
    switch (subscription.billingCycle) {
      BillingCycle.weekly => subscription.amountInCentavos * 52 / 100,
      BillingCycle.monthly => subscription.amountInCentavos * 12 / 100,
      BillingCycle.quarterly => subscription.amountInCentavos * 4 / 100,
      BillingCycle.biAnnual => subscription.amountInCentavos * 2 / 100,
      BillingCycle.yearly => subscription.amountInCentavos / 100,
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
