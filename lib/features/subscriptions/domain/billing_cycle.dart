enum BillingCycle { weekly, monthly, quarterly, biAnnual, yearly }

extension BillingCycleDetails on BillingCycle {
  String get label => switch (this) {
    BillingCycle.weekly => 'Weekly',
    BillingCycle.monthly => 'Monthly',
    BillingCycle.quarterly => 'Quarterly',
    BillingCycle.biAnnual => 'Bi-annual',
    BillingCycle.yearly => 'Yearly',
  };

  int? get monthInterval => switch (this) {
    BillingCycle.weekly => null,
    BillingCycle.monthly => 1,
    BillingCycle.quarterly => 3,
    BillingCycle.biAnnual => 6,
    BillingCycle.yearly => 12,
  };

  static BillingCycle fromLabel(String label) =>
      BillingCycle.values.firstWhere((cycle) => cycle.label == label);
}
