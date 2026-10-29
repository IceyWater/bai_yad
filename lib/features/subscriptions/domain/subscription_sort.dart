import 'cost_calculator.dart';
import 'renewal_calculator.dart';
import 'subscription.dart';

enum SubscriptionSort { nextRenewal, price, name }

extension SubscriptionSortLabel on SubscriptionSort {
  String get label => switch (this) {
    SubscriptionSort.nextRenewal => 'Next renewal',
    SubscriptionSort.price => 'Monthly price',
    SubscriptionSort.name => 'Name',
  };
}

List<Subscription> sortSubscriptions(
  Iterable<Subscription> subscriptions,
  SubscriptionSort sort, {
  DateTime? from,
}) {
  final entries = List<Subscription>.of(subscriptions);
  final today = from ?? DateTime.now();
  entries.sort((first, second) {
    final comparison = switch (sort) {
      SubscriptionSort.nextRenewal =>
        nextRenewal(
          first.anchorDate,
          first.billingCycle,
          from: today,
        ).compareTo(
          nextRenewal(second.anchorDate, second.billingCycle, from: today),
        ),
      SubscriptionSort.price => monthlyCost(
        first,
      ).compareTo(monthlyCost(second)),
      SubscriptionSort.name => first.name.toLowerCase().compareTo(
        second.name.toLowerCase(),
      ),
    };
    if (comparison != 0) return comparison;
    final byName = first.name.toLowerCase().compareTo(
      second.name.toLowerCase(),
    );
    return byName != 0 ? byName : first.id.compareTo(second.id);
  });
  return entries;
}
