// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bai_yad/features/subscriptions/application/subscription_providers.dart';
import 'package:bai_yad/features/subscriptions/data/subscription_repository.dart';
import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_category.dart';
import 'package:bai_yad/main.dart';

void main() {
  testWidgets('saved profile skips onboarding and empty storage stays empty', (
    WidgetTester tester,
  ) async {
    final repository = _WidgetTestRepository(
      profileName: 'Saved User',
      empty: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL COMMITMENT'), findsOneWidget);
    expect(find.byKey(const Key('getStartedButton')), findsNothing);

    await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const PageStorageKey('subscriptionList')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.text('No subscriptions found'), findsOneWidget);
    expect(find.text('Adobe Creative Cloud'), findsNothing);
  });

  testWidgets('launch screen opens list and adds a subscription', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            _WidgetTestRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Vault ready. Launching...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('getStartedButton')));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL COMMITMENT'), findsOneWidget);
    expect(find.text('₱3,470.17'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottomNavBREAKDOWN')));
    await tester.pump();
    expect(find.text('CATEGORY BREAKDOWN'), findsOneWidget);
    expect(find.text('₱3,470.17'), findsOneWidget);

    await tester.tap(find.byKey(const Key('annualPeriodButton')));
    await tester.pump();
    expect(find.text('₱41,642'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
    await tester.pump();
    expect(find.byKey(const Key('subscriptionSearchField')), findsOneWidget);
    expect(find.text('Adobe Creative Cloud'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addSubscriptionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Add Subscription'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('newSubscriptionNameField')),
      'Cloud Storage Plus',
    );
    await tester.enterText(
      find.byKey(const Key('newSubscriptionAmountField')),
      '299',
    );
    await tester.tap(find.byKey(const Key('saveSubscriptionButton')));
    await tester.pumpAndSettle();

    expect(find.text('Cloud Storage Plus'), findsOneWidget);
    expect(find.text('₱299'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addSubscriptionButton')));
    await tester.pumpAndSettle();
    expect(find.text('₱0.01 to ₱99,999,999.99'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('newSubscriptionAmountField')),
      '100000000',
    );
    await tester.tap(find.byKey(const Key('saveSubscriptionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Maximum cost is ₱99,999,999.99'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('newSubscriptionAmountField')),
      '0',
    );
    await tester.tap(find.byKey(const Key('saveSubscriptionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid cost'), findsOneWidget);
  });

  testWidgets('sorting remains composed with category filtering', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            _WidgetTestRepository(profileName: 'Saved User'),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('subscriptionSortDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly price').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Streaming').first);
    await tester.pumpAndSettle();

    final spotify = find.descendant(
      of: find.byKey(const ValueKey('spotify-premium')),
      matching: find.text('Spotify Premium'),
    );
    final netflix = find.descendant(
      of: find.byKey(const ValueKey('netflix-ph')),
      matching: find.text('Netflix PH (4K)'),
    );
    expect(spotify, findsOneWidget);
    expect(netflix, findsOneWidget);
    expect(
      tester.getTopLeft(spotify).dy,
      lessThan(tester.getTopLeft(netflix).dy),
    );
    expect(find.text('PLDT Home Fiber'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('subscriptionSearchField')),
      'not found',
    );
    await tester.pumpAndSettle();
    expect(find.text('No subscriptions found'), findsOneWidget);
  });

  testWidgets('edits, flags, marks used, and undoes subscription deletion', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionRepositoryProvider.overrideWithValue(
            _WidgetTestRepository(profileName: 'Saved User'),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
    await tester.pumpAndSettle();

    final editButton = find.byKey(
      const Key('editSubscription-adobe-creative-cloud'),
    );
    await tester.ensureVisible(editButton);
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(find.text('Edit Subscription'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('newSubscriptionNameField')),
      'Adobe Updated',
    );
    await tester.enterText(
      find.byKey(const Key('newSubscriptionAmountField')),
      '1299.99',
    );
    await tester.tap(find.byKey(const Key('saveSubscriptionButton')));
    await tester.pumpAndSettle();
    expect(find.text('Adobe Updated'), findsOneWidget);
    expect(find.text('₱1,299.99'), findsOneWidget);

    final rareUseButton = find.byKey(
      const Key('rarelyUsedToggle-adobe-creative-cloud'),
    );
    await tester.ensureVisible(rareUseButton);
    await tester.tap(rareUseButton);
    await tester.pumpAndSettle();
    expect(find.text('Rarely used'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottomNavHOME')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Adobe Updated · ₱1,299.99/mo potential'),
      findsOneWidget,
    );
    final markUsedButton = find.text('Mark as used');
    await tester.ensureVisible(markUsedButton);
    await tester.tap(markUsedButton);
    await tester.pumpAndSettle();
    expect(find.text('RARELY USED'), findsNothing);

    await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
    await tester.pumpAndSettle();
    final deleteButton = find.byKey(
      const Key('deleteSubscription-adobe-creative-cloud'),
    );
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Adobe Updated'), findsNothing);
    expect(find.text('Subscription deleted'), findsOneWidget);
    expect(find.byKey(const Key('deleteSnackBarDismiss')), findsOneWidget);
    await tester.tap(find.byKey(const Key('deleteSnackBarUndo')));
    await tester.pumpAndSettle();
    expect(find.text('Adobe Updated'), findsOneWidget);
    expect(find.text('₱1,299.99'), findsOneWidget);

    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('deleteSnackBarDismiss')));
    await tester.pumpAndSettle();
    expect(find.text('Subscription deleted'), findsNothing);
    expect(find.text('Adobe Updated'), findsNothing);
  });
}

class _WidgetTestRepository implements SubscriptionRepository {
  _WidgetTestRepository({this._profileName, bool empty = false}) {
    if (empty) _subscriptions.clear();
  }

  final List<Subscription> _subscriptions = [
    _subscription(
      id: 'adobe-creative-cloud',
      name: 'Adobe Creative Cloud',
      amount: 1199,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.software,
      date: DateTime(2026, 10, 16),
    ),
    _subscription(
      id: 'pldt-home-fiber',
      name: 'PLDT Home Fiber',
      amount: 1499,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.utilities,
      date: DateTime(2026, 10, 14),
    ),
    _subscription(
      id: 'netflix-ph',
      name: 'Netflix PH (4K)',
      amount: 549,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.streaming,
      date: DateTime(2026, 10, 23),
    ),
    _subscription(
      id: 'spotify-premium',
      name: 'Spotify Premium',
      amount: 149,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.streaming,
      date: DateTime(2026, 10, 30),
    ),
    _subscription(
      id: 'google-one',
      name: 'Google One (100GB)',
      amount: 890,
      cycle: BillingCycle.yearly,
      category: SubscriptionCategory.workTools,
      date: DateTime(2026, 11, 20),
    ),
  ];

  String? _profileName;

  @override
  Future<List<Subscription>> loadSubscriptions() async =>
      List.unmodifiable(_subscriptions);

  @override
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    _subscriptions
      ..clear()
      ..addAll(subscriptions);
  }

  @override
  Future<void> clearSubscriptions() async => _subscriptions.clear();

  @override
  Future<String?> loadProfileName() async => _profileName;

  @override
  Future<void> saveProfileName(String name) async {
    _profileName = name;
  }
}

Subscription _subscription({
  required String id,
  required String name,
  required double amount,
  required BillingCycle cycle,
  required SubscriptionCategory category,
  required DateTime date,
}) => Subscription(
  id: id,
  name: name,
  amount: amount,
  billingCycle: cycle,
  category: category,
  anchorDate: date,
  createdAt: DateTime(2026, 1, 1),
);
