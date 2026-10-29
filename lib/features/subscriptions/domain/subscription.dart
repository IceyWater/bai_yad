import 'billing_cycle.dart';
import 'subscription_category.dart';

class Subscription {
  Subscription({
    required this.id,
    required this.name,
    required double amount,
    required this.billingCycle,
    required this.category,
    required this.anchorDate,
    required this.createdAt,
    this.colorArgb,
    this.isRarelyUsed = false,
    this.notes,
  }) : amountInCentavos = (amount * 100 + 1e-7).round();

  final String id;
  final String name;
  final int amountInCentavos;
  double get amount => amountInCentavos / 100;
  final BillingCycle billingCycle;
  final SubscriptionCategory category;
  final DateTime anchorDate;
  final int? colorArgb;
  final bool isRarelyUsed;
  final String? notes;
  final DateTime createdAt;

  Subscription copyWith({
    String? id,
    String? name,
    double? amount,
    BillingCycle? billingCycle,
    SubscriptionCategory? category,
    DateTime? anchorDate,
    int? colorArgb,
    bool? isRarelyUsed,
    String? notes,
    bool clearNotes = false,
    DateTime? createdAt,
  }) => Subscription(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    billingCycle: billingCycle ?? this.billingCycle,
    category: category ?? this.category,
    anchorDate: anchorDate ?? this.anchorDate,
    colorArgb: colorArgb ?? this.colorArgb,
    isRarelyUsed: isRarelyUsed ?? this.isRarelyUsed,
    notes: clearNotes ? null : notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'billingCycle': billingCycle.name,
    'category': category.name,
    'anchorDate': anchorDate.toIso8601String(),
    'colorArgb': colorArgb,
    'isRarelyUsed': isRarelyUsed,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Subscription.fromJson(Map<String, Object?> json) => Subscription(
    id: json['id'] as String,
    name: json['name'] as String,
    amount: (json['amount'] as num).toDouble(),
    billingCycle: BillingCycle.values.byName(json['billingCycle'] as String),
    category: SubscriptionCategory.values.byName(json['category'] as String),
    anchorDate: DateTime.parse(json['anchorDate'] as String),
    colorArgb: json['colorArgb'] as int?,
    isRarelyUsed: json['isRarelyUsed'] as bool? ?? false,
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          other.id == id &&
          other.name == name &&
          other.amountInCentavos == amountInCentavos &&
          other.billingCycle == billingCycle &&
          other.category == category &&
          other.anchorDate == anchorDate &&
          other.colorArgb == colorArgb &&
          other.isRarelyUsed == isRarelyUsed &&
          other.notes == notes &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amountInCentavos,
    billingCycle,
    category,
    anchorDate,
    colorArgb,
    isRarelyUsed,
    notes,
    createdAt,
  );
}
