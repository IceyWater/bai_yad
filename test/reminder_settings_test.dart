import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bai_yad/features/subscriptions/application/reminder_settings_provider.dart';
import 'package:bai_yad/features/subscriptions/application/reminder_service.dart';
import 'package:bai_yad/features/subscriptions/application/subscription_providers.dart';
import 'package:bai_yad/features/subscriptions/data/subscription_repository.dart';
import 'package:bai_yad/features/subscriptions/data/shared_preferences_reminder_settings_repository.dart';
import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_category.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription.dart';
import 'package:bai_yad/features/subscriptions/domain/reminder_settings.dart';
import 'package:bai_yad/features/subscriptions/presentation/subscriptions_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reminder settings default to disabled with a three-day lead', () async {
    final repository = SharedPreferencesReminderSettingsRepository();

    expect(await repository.load(), const ReminderSettings());
  });

  test('reminder settings persist enabled state and lead time', () async {
    final repository = SharedPreferencesReminderSettingsRepository();
    const settings = ReminderSettings(enabled: true, daysBefore: 7);

    await repository.save(settings);

    expect(await repository.load(), settings);
  });

  test('unsupported saved lead times fall back to three days', () async {
    SharedPreferences.setMockInitialValues({'reminders.daysBefore.v1': 5});

    expect(
      await SharedPreferencesReminderSettingsRepository().load(),
      const ReminderSettings(),
    );
  });

  test('controller persists setting updates', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(reminderSettingsControllerProvider.future);

    await container
        .read(reminderSettingsControllerProvider.notifier)
        .updateSettings(enabled: true, daysBefore: 1);

    expect(
      container.read(reminderSettingsControllerProvider).requireValue,
      const ReminderSettings(enabled: true, daysBefore: 1),
    );
    expect(
      await SharedPreferencesReminderSettingsRepository().load(),
      const ReminderSettings(enabled: true, daysBefore: 1),
    );
  });

  test(
    'unsupported lead times are rejected without changing settings',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(reminderSettingsControllerProvider.future);

      await expectLater(
        container
            .read(reminderSettingsControllerProvider.notifier)
            .updateSettings(daysBefore: 5),
        throwsArgumentError,
      );

      expect(
        container.read(reminderSettingsControllerProvider).requireValue,
        const ReminderSettings(),
      );
    },
  );

  testWidgets('permission denial leaves reminders disabled', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeReminderService(permissionGranted: false);
    final container = ProviderContainer(
      overrides: [reminderServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SubscriptionsScreen(name: 'Test')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminderSettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminderEnabledSwitch')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Permission was not granted'), findsOneWidget);
    expect(service.permissionRequests, 1);
    expect(service.schedules, 0);
    expect(
      container.read(reminderSettingsControllerProvider).requireValue.enabled,
      isFalse,
    );
  });

  testWidgets('enabling requests permission and schedules current settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _FakeReminderService(permissionGranted: true);
    final container = ProviderContainer(
      overrides: [reminderServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SubscriptionsScreen(name: 'Test')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminderSettingsButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 day'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reminderEnabledSwitch')));
    await tester.pumpAndSettle();

    expect(service.permissionRequests, 1);
    expect(service.schedules, 1);
    expect(service.lastDaysBefore, 1);
    expect(
      container.read(reminderSettingsControllerProvider).requireValue.enabled,
      isTrue,
    );
    expect(
      container
          .read(reminderSettingsControllerProvider)
          .requireValue
          .daysBefore,
      1,
    );

    await tester.tap(find.byKey(const Key('reminderEnabledSwitch')));
    await tester.pumpAndSettle();
    expect(service.cancellations, 1);
    expect(
      container.read(reminderSettingsControllerProvider).requireValue.enabled,
      isFalse,
    );
  });

  testWidgets('enabled reminders restore on launch and refresh after changes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'reminders.enabled.v1': true,
      'reminders.daysBefore.v1': 1,
    });
    final service = _FakeReminderService(permissionGranted: true);
    final container = ProviderContainer(
      overrides: [
        reminderServiceProvider.overrideWithValue(service),
        subscriptionRepositoryProvider.overrideWithValue(
          _MemorySubscriptionRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SubscriptionsScreen(name: 'Test')),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.schedules, 1);
    expect(service.lastDaysBefore, 1);

    await container
        .read(subscriptionControllerProvider.notifier)
        .add(_testSubscription());
    await tester.pumpAndSettle();

    expect(service.schedules, 2);
  });
}

class _FakeReminderService implements ReminderService {
  _FakeReminderService({required this.permissionGranted});

  final bool permissionGranted;
  int permissionRequests = 0;
  int schedules = 0;
  int cancellations = 0;
  int? lastDaysBefore;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> schedule(
    Iterable<Subscription> subscriptions, {
    required DateTime now,
    required int daysBefore,
  }) async {
    schedules++;
    lastDaysBefore = daysBefore;
  }

  @override
  Future<void> cancelAll() async => cancellations++;
}

class _MemorySubscriptionRepository implements SubscriptionRepository {
  List<Subscription> subscriptions = [];

  @override
  Future<void> clearSubscriptions() async => subscriptions = [];

  @override
  Future<List<Subscription>> loadSubscriptions() async => subscriptions;

  @override
  Future<String?> loadProfileName() async => null;

  @override
  Future<void> saveProfileName(String name) async {}

  @override
  Future<void> saveSubscriptions(List<Subscription> value) async {
    subscriptions = List.of(value);
  }
}

Subscription _testSubscription() => Subscription(
  id: 'renewal-test',
  name: 'Test plan',
  amount: 100,
  billingCycle: BillingCycle.monthly,
  category: SubscriptionCategory.streaming,
  anchorDate: DateTime(2026, 10, 31),
  createdAt: DateTime(2026, 1, 1),
);
