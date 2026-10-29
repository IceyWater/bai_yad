import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bai_yad/core/theme/app_theme.dart';
import 'package:bai_yad/features/onboarding/profile_setup_screen.dart';
import 'package:bai_yad/features/subscriptions/application/reminder_settings_provider.dart';
import 'package:bai_yad/features/subscriptions/application/reminder_service.dart';
import 'package:bai_yad/features/subscriptions/application/subscription_providers.dart';
import 'package:bai_yad/features/subscriptions/data/reminder_settings_repository.dart';
import 'package:bai_yad/features/subscriptions/data/subscription_repository.dart';
import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/cost_calculator.dart';
import 'package:bai_yad/features/subscriptions/domain/reminder_settings.dart';
import 'package:bai_yad/features/subscriptions/domain/renewal_calculator.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_category.dart';
import 'package:bai_yad/features/subscriptions/presentation/home_tab.dart';
import 'package:bai_yad/features/subscriptions/presentation/subscriptions_screen.dart';

void main() {
  group('ProfileSetupScreen', () {
    testWidgets('starts blank and remains usable at large sizes', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final size in [const Size(320, 568), const Size(800, 1280)]) {
        tester.view.physicalSize = size;
        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(_profileApp(scale));
          await tester.pumpAndSettle();

          final field = tester.widget<TextField>(
            find.byKey(const Key('profileNameInput')),
          );
          expect(field.controller?.text, isEmpty);
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
      }
    });
  });

  group('LaunchScreen', () {
    testWidgets('shows a clean launch state across supported surfaces', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      for (final size in [const Size(320, 568), const Size(800, 1280)]) {
        tester.view.physicalSize = size;
        for (final scale in [1.5, 2.0]) {
          await tester.pumpWidget(_launchApp(scale));
          await tester.pump(const Duration(milliseconds: 700));
          expect(find.text('Vault ready. Launching...'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });
  });

  group('Home tab', () {
    testWidgets('fits long names and large peso values at all target sizes', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final subscriptions = [
        _fixture(
          name: 'A very long subscription name that should truncate cleanly',
          amount: 99999999.99,
        ),
      ];

      for (final size in [const Size(320, 568), const Size(800, 1280)]) {
        tester.view.physicalSize = size;
        for (final scale in [1.5, 2.0]) {
          await _pumpHome(tester, size: size, textScale: scale, subscriptions: subscriptions);
          expect(find.text('TOTAL COMMITMENT'), findsOneWidget);
          final layoutError = tester.takeException();
          expect(layoutError, isNull, reason: '$layoutError');
        }
      }

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group('Subscriptions tab', () {
    testWidgets('handles long names, duplicate names, and large amounts', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final subscriptions = [
        _fixture(
          id: 'long-name',
          name: 'A very long subscription name that should truncate cleanly',
          amount: 99999999.99,
        ),
        _fixture(id: 'duplicate-one', name: 'Shared name', amount: 19.99),
        _fixture(id: 'duplicate-two', name: 'Shared name', amount: 29.99),
      ];

      for (final size in [const Size(320, 568), const Size(800, 1280)]) {
        for (final scale in [1.5, 2.0]) {
          await _pumpShell(
            tester,
            size: size,
            textScale: scale,
            subscriptions: subscriptions,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'shell at $size and $scale',
          );
          await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'list controls at $size and $scale',
          );
          expect(find.byKey(const Key('subscriptionSearchField')), findsOneWidget);
          await tester.drag(
            find.byKey(const PageStorageKey('subscriptionList')),
            const Offset(0, -1000),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('duplicate-one')), findsOneWidget);
          expect(find.byKey(const ValueKey('duplicate-two')), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'subscription cards at $size and $scale',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }

      await _pumpShell(
        tester,
        size: const Size(390, 844),
        textScale: 1,
        subscriptions: subscriptions,
      );
      await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
      await tester.pumpAndSettle();
      final longName = tester.widget<Text>(
        find.text('A very long subscription name that should truncate cleanly'),
      );
      expect(longName.maxLines, 1);
      expect(longName.overflow, TextOverflow.ellipsis);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('shows a useful empty result state and reset action', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(390, 844),
        textScale: 1,
        empty: true,
      );
      expect(find.text('TOTAL COMMITMENT'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('subscriptionSearchField')), findsOneWidget);
      expect(find.text('No subscriptions found'), findsOneWidget);
      expect(find.text('Try another search or category.'), findsOneWidget);
    });
  });
}

Widget _profileApp(double textScale) => ProviderScope(
  overrides: [
    subscriptionRepositoryProvider.overrideWithValue(_MemoryRepository()),
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: ProfileSetupScreen(destinationBuilder: (_) => const SizedBox()),
  ),
);

Widget _launchApp(double textScale) => ProviderScope(
  overrides: [
    subscriptionRepositoryProvider.overrideWithValue(_MemoryRepository()),
  ],
  child: MaterialApp(
    theme: AppTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: const LaunchScreen(),
  ),
);

Future<void> _pumpShell(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  List<Subscription>? subscriptions,
  bool empty = false,
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(
          _MemoryRepository(subscriptions: subscriptions, empty: empty),
        ),
        reminderSettingsRepositoryProvider.overrideWithValue(
          _MemoryReminderSettingsRepository(),
        ),
        reminderServiceProvider.overrideWithValue(_FakeReminderService()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const SubscriptionsScreen(name: 'Alex'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required double textScale,
  required List<Subscription> subscriptions,
}) async {
  tester.view.physicalSize = size;
  final monthlyTotal = totalMonthlyCost(subscriptions);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: HomeTab(
          subscriptions: subscriptions,
          rarelyUsedSubscriptions: const [],
          renewals: upcomingRenewals(subscriptions),
          monthlyTotal: monthlyTotal,
          annualTotal: totalAnnualCost(subscriptions),
          monthlyCategories: const [],
          yearly: false,
          onYearlyChanged: (_) {},
          onMarkUsed: (_) {},
          onDelete: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MemoryReminderSettingsRepository implements ReminderSettingsRepository {
  ReminderSettings settings = const ReminderSettings();

  @override
  Future<ReminderSettings> load() async => settings;

  @override
  Future<void> save(ReminderSettings value) async => settings = value;
}

class _FakeReminderService implements ReminderService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> schedule(
    Iterable<Subscription> subscriptions, {
    required DateTime now,
    required int daysBefore,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}

class _MemoryRepository implements SubscriptionRepository {
  _MemoryRepository({List<Subscription>? subscriptions, bool empty = false})
    : _subscriptions = subscriptions ?? (empty ? [] : [_fixture()]);

  final List<Subscription> _subscriptions;

  @override
  Future<void> clearSubscriptions() async {}

  @override
  Future<List<Subscription>> loadSubscriptions() async => _subscriptions;

  @override
  Future<String?> loadProfileName() async => null;

  @override
  Future<void> saveProfileName(String name) async {}

  @override
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    _subscriptions
      ..clear()
      ..addAll(subscriptions);
  }
}

Subscription _fixture({
  String id = 'fixture',
  String name = 'Example subscription',
  double amount = 100,
}) =>
    Subscription(
      id: id,
      name: name,
      amount: amount,
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.streaming,
      anchorDate: DateTime.now(),
      createdAt: DateTime(2026, 1, 1),
    );