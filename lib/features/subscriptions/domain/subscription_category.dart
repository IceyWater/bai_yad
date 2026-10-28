enum SubscriptionCategory {
  streaming,
  software,
  utilities,
  workTools,
  productivity,
}

extension SubscriptionCategoryDetails on SubscriptionCategory {
  String get label => switch (this) {
    SubscriptionCategory.streaming => 'Streaming',
    SubscriptionCategory.software => 'Software',
    SubscriptionCategory.utilities => 'Utilities',
    SubscriptionCategory.workTools => 'Work Tools',
    SubscriptionCategory.productivity => 'Productivity',
  };

  static SubscriptionCategory fromLabel(String label) => SubscriptionCategory
      .values
      .firstWhere((category) => category.label == label);
}
