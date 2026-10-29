import 'package:flutter_test/flutter_test.dart';
import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/renewal_calculator.dart';

void main() {
  group('nextRenewal', () {
    test('monthly dates remain anchored to the original day', () {
      expect(
        nextRenewal(
          DateTime(2026, 1, 31),
          BillingCycle.monthly,
          from: DateTime(2026, 2, 1),
        ),
        DateTime(2026, 2, 28),
      );
      expect(
        nextRenewal(
          DateTime(2026, 1, 31),
          BillingCycle.monthly,
          from: DateTime(2026, 2, 28),
        ),
        DateTime(2026, 2, 28),
      );
      expect(
        nextRenewal(
          DateTime(2026, 1, 31),
          BillingCycle.monthly,
          from: DateTime(2026, 3, 1),
        ),
        DateTime(2026, 3, 31),
      );
    });

    test('yearly February 29 anchors clamp correctly in non-leap years', () {
      expect(
        nextRenewal(
          DateTime(2024, 2, 29),
          BillingCycle.yearly,
          from: DateTime(2025, 2, 1),
        ),
        DateTime(2025, 2, 28),
      );
      expect(
        nextRenewal(
          DateTime(2024, 2, 29),
          BillingCycle.yearly,
          from: DateTime(2025, 3, 1),
        ),
        DateTime(2026, 2, 28),
      );
      expect(
        nextRenewal(
          DateTime(2024, 2, 29),
          BillingCycle.yearly,
          from: DateTime(2028, 2, 28),
        ),
        DateTime(2028, 2, 29),
      );
    });

    test('handles year rollover and weekly recurrence', () {
      expect(
        nextRenewal(
          DateTime(2025, 12, 31),
          BillingCycle.monthly,
          from: DateTime(2026, 1, 1),
        ),
        DateTime(2026, 1, 31),
      );
      expect(
        nextRenewal(
          DateTime(2026, 10, 21),
          BillingCycle.weekly,
          from: DateTime(2026, 10, 28),
        ),
        DateTime(2026, 10, 28),
      );
    });

    test(
      'treats a renewal today as upcoming and supports far-past anchors',
      () {
        expect(
          nextRenewal(
            DateTime(2026, 10, 28),
            BillingCycle.monthly,
            from: DateTime(2026, 10, 28, 23),
          ),
          DateTime(2026, 10, 28),
        );
        expect(
          nextRenewal(
            DateTime(2000, 1, 31),
            BillingCycle.monthly,
            from: DateTime(2026, 10, 28),
          ),
          DateTime(2026, 10, 31),
        );
      },
    );
  });

  group('renewalLabel', () {
    final today = DateTime(2026, 10, 28);

    test('uses stable date-only labels for today, tomorrow, and later', () {
      expect(renewalLabel(DateTime(2026, 10, 28, 23), today: today), 'Today');
      expect(renewalLabel(DateTime(2026, 10, 29), today: today), 'Tomorrow');
      expect(renewalLabel(DateTime(2026, 11, 2), today: today), 'In 5 days');
      expect(renewalLabel(DateTime(2026, 10, 27), today: today), 'Overdue');
    });
  });
}
