import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bai_yad/core/theme/app_theme.dart';
import 'package:bai_yad/core/theme/app_colors.dart';
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
import 'package:bai_yad/features/subscriptions/presentation/subscriptions_list.dart';
import 'package:bai_yad/features/subscriptions/presentation/subscription_tabs.dart';

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
    testWidgets('keeps rarely used items calm and separated', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final rarelyUsed = [
        _fixture(id: 'rare-one', name: '3333').copyWith(isRarelyUsed: true),
        _fixture(id: 'rare-two', name: 'test').copyWith(isRarelyUsed: true),
      ];

      await _pumpHome(
        tester,
        size: const Size(390, 844),
        textScale: 1,
        subscriptions: rarelyUsed,
        rarelyUsedSubscriptions: rarelyUsed,
      );

      final card = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('RARELY USED'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((card.decoration! as BoxDecoration).color, AppColors.panel);
      final firstItem = tester.getTopLeft(find.textContaining('3333 ·'));
      final secondItem = tester.getTopLeft(find.textContaining('test ·'));
      expect(secondItem.dy - firstItem.dy, greaterThan(45));

      final markUsed = tester.widget<TextButton>(find.byType(TextButton).first);
      expect(markUsed.style?.backgroundColor, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows annual total in a single-row period selector', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final categories = [
        const CategorySpending(
          name: 'Utilities & Fiber',
          amount: 43,
          color: Colors.green,
        ),
        const CategorySpending(
          name: 'Software & Cloud',
          amount: 35,
          color: Colors.purple,
        ),
        const CategorySpending(
          name: 'Streaming & Media',
          amount: 22,
          color: Colors.orange,
        ),
      ];
      await _pumpHome(
        tester,
        size: const Size(390, 844),
        textScale: 1,
        subscriptions: [_fixture(amount: 3470.17)],
        categories: categories,
      );

      expect(
        tester
            .widget<Text>(find.byKey(const Key('homeTotalAmount')))
            .textSpan!
            .toPlainText(),
        '₱3,470.17',
      );
      final annualLabel = tester.widget<RichText>(
        find.descendant(
          of: find.byKey(const Key('annualPeriodButton')),
          matching: find.byType(RichText),
        ),
      );
      expect(annualLabel.text.toPlainText(), 'Yearly (₱41,642)');
      final selectorSize = tester.getSize(
        find.byKey(const Key('homePeriodSelector')),
      );
      expect(selectorSize.width, lessThan(210));
      expect(selectorSize.height, lessThan(55));
      final totalRight = tester
          .getRect(find.byKey(const Key('homeTotalAmount')))
          .right;
      final cadenceLeft = tester.getTopLeft(find.text('/mo')).dx;
      expect((cadenceLeft - totalRight - 7).abs(), lessThan(1));
      final legendTops = [
        tester.getTopLeft(find.text('Utilities 43%')).dy,
        tester.getTopLeft(find.text('Software 35%')).dy,
        tester.getTopLeft(find.text('Media 22%')).dy,
      ];
      expect((legendTops[0] - legendTops[1]).abs(), lessThan(1));
      expect((legendTops[1] - legendTops[2]).abs(), lessThan(1));

      expect(tester.takeException(), isNull);
    });

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
          await _pumpHome(
            tester,
            size: size,
            textScale: scale,
            subscriptions: subscriptions,
          );
          expect(find.text('TOTAL COMMITMENT'), findsOneWidget);
          final layoutError = tester.takeException();
          expect(
            layoutError,
            isNull,
            reason:
                '$size at text scale $scale: ${layoutError is FlutterError ? layoutError.toStringDeep() : layoutError}',
          );
        }
      }

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  });

  group('Subscriptions tab', () {
    testWidgets('keeps header compact and search clear action functional', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        size: const Size(390, 844),
        textScale: 1,
        subscriptions: [_fixture(name: 'Cloud Storage')],
      );
      await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(SubscriptionsHeader)).height,
        lessThan(80),
      );
      final search = find.byKey(const Key('subscriptionSearchField'));
      expect(
        tester.getSize(find.byKey(const Key('addSubscriptionButton'))).height,
        greaterThanOrEqualTo(44),
      );
      await tester.enterText(search, 'no match');
      await tester.pumpAndSettle();
      expect(find.text('No subscriptions found'), findsOneWidget);
      await tester.tap(find.byKey(const Key('clearSubscriptionSearchButton')));
      await tester.pumpAndSettle();
      expect(find.text('Cloud Storage'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('separates subscription rows and prioritizes names', (
      tester,
    ) async {
      final subscriptions = [
        _fixture(id: 'first', name: '3333', amount: 232),
        _fixture(id: 'second', name: 'test', amount: 333),
      ];
      await _pumpShell(
        tester,
        size: const Size(390, 844),
        textScale: 1,
        subscriptions: subscriptions,
      );
      await tester.tap(find.byKey(const Key('bottomNavSUBSCRIPTIONS')));
      await tester.pumpAndSettle();

      final firstCard = tester.getRect(find.byKey(const ValueKey('first')));
      final secondCard = tester.getRect(find.byKey(const ValueKey('second')));
      expect(secondCard.top - firstCard.bottom, 16);
      expect(
        tester.widget<Text>(find.text('3333')).style?.fontWeight,
        FontWeight.w500,
      );
      expect(
        tester.widget<Text>(find.text('₱232')).style?.fontWeight,
        FontWeight.w400,
      );
      expect(
        tester.getSize(find.byKey(const Key('deleteSubscription-first'))).width,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);
    });

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
          expect(
            find.byKey(const Key('subscriptionSearchField')),
            findsOneWidget,
          );
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
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
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
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
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
  List<CategorySpending> categories = const [],
  List<Subscription> rarelyUsedSubscriptions = const [],
}) async {
  tester.view.physicalSize = size;
  final monthlyTotal = totalMonthlyCost(subscriptions);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: HomeTab(
          subscriptions: subscriptions,
          rarelyUsedSubscriptions: rarelyUsedSubscriptions,
          renewals: upcomingRenewals(subscriptions),
          monthlyTotal: monthlyTotal,
          annualTotal: totalAnnualCost(subscriptions),
          monthlyCategories: categories,
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
}) => Subscription(
  id: id,
  name: name,
  amount: amount,
  billingCycle: BillingCycle.monthly,
  category: SubscriptionCategory.streaming,
  anchorDate: DateTime.now(),
  createdAt: DateTime(2026, 1, 1),
);
