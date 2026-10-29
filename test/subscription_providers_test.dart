import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bai_yad/features/subscriptions/application/subscription_providers.dart';
import 'package:bai_yad/features/subscriptions/data/subscription_repository.dart';
import 'package:bai_yad/features/subscriptions/domain/billing_cycle.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription.dart';
import 'package:bai_yad/features/subscriptions/domain/subscription_category.dart';

void main() {
  test('controller loads, adds, removes, and persists subscriptions', () async {
    final repository = _MemorySubscriptionRepository();
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(subscriptionControllerProvider.future),
      isEmpty,
    );

    final subscription = _subscription('streaming');
    await container
        .read(subscriptionControllerProvider.notifier)
        .add(subscription);

    expect(container.read(subscriptionControllerProvider).requireValue, [
      subscription,
    ]);
    expect(repository.savedSubscriptions, [subscription]);

    await container
        .read(subscriptionControllerProvider.notifier)
        .remove(subscription);

    expect(
      container.read(subscriptionControllerProvider).requireValue,
      isEmpty,
    );
    expect(repository.savedSubscriptions, isEmpty);
  });

  test('controller updates by ID and persists the replacement', () async {
    final repository = _MemorySubscriptionRepository();
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(subscriptionControllerProvider.future);

    final original = _subscription('streaming');
    await container.read(subscriptionControllerProvider.notifier).add(original);
    final edited = original.copyWith(name: 'Updated name', amount: 199);
    await container
      .read(subscriptionControllerProvider.notifier)
      .updateSubscription(edited);

    expect(container.read(subscriptionControllerProvider).requireValue, [edited]);
    expect(repository.savedSubscriptions, [edited]);
    expect(edited.id, original.id);
    expect(edited.createdAt, original.createdAt);
  });

  test('controller restores a removed subscription at its saved position', () async {
    final repository = _MemorySubscriptionRepository();
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(subscriptionControllerProvider.future);

    final first = _subscription('first');
    final middle = _subscription('middle');
    final last = _subscription('last');
    final controller = container.read(subscriptionControllerProvider.notifier);
    await controller.add(last);
    await controller.add(middle);
    await controller.add(first);
    await controller.remove(middle);
    await controller.restore(middle, index: 1);

    expect(container.read(subscriptionControllerProvider).requireValue, [
      first,
      middle,
      last,
    ]);
    expect(repository.savedSubscriptions, [first, middle, last]);
  });

  test('controller rejects updates for unknown IDs', () async {
    final repository = _MemorySubscriptionRepository();
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(subscriptionControllerProvider.future);

    await expectLater(
      container
          .read(subscriptionControllerProvider.notifier)
          .updateSubscription(_subscription('missing')),
      throwsA(isA<StateError>()),
    );
    expect(container.read(subscriptionControllerProvider).requireValue, isEmpty);
    expect(repository.savedSubscriptions, isEmpty);
  });

  test('profile controller persists the cleaned profile name', () async {
    final repository = _MemorySubscriptionRepository();
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    expect(await container.read(profileControllerProvider.future), isNull);
    await container.read(profileControllerProvider.notifier).save('  Alex  ');

    expect(container.read(profileControllerProvider).requireValue, 'Alex');
    expect(repository.profileName, 'Alex');
  });

  test('failed writes roll back optimistic subscription state', () async {
    final repository = _MemorySubscriptionRepository()..failWrites = true;
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(subscriptionControllerProvider.future);

    await expectLater(
      container
          .read(subscriptionControllerProvider.notifier)
          .add(_subscription('streaming')),
      throwsA(isA<StateError>()),
    );

    expect(
      container.read(subscriptionControllerProvider).requireValue,
      isEmpty,
    );
  });

  test('concurrent writes persist the latest controller state', () async {
    final repository = _DelayedWriteRepository();
    final container = ProviderContainer(
      overrides: [subscriptionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(subscriptionControllerProvider.future);

    final controller = container.read(subscriptionControllerProvider.notifier);
    final first = _subscription('first');
    final second = _subscription('second');
    final firstWrite = controller.add(first);
    final secondWrite = controller.add(second);

    repository.writeGates[0].complete();
    await firstWrite;
    await repository.secondWriteStarted.future;
    repository.writeGates[1].complete();
    await secondWrite;

    expect(container.read(subscriptionControllerProvider).requireValue, [
      second,
      first,
    ]);
    expect(repository.savedSubscriptions, [second, first]);
  });
}

class _MemorySubscriptionRepository implements SubscriptionRepository {
  List<Subscription> savedSubscriptions = [];
  String? profileName;
  bool failWrites = false;

  @override
  Future<List<Subscription>> loadSubscriptions() async =>
      List.unmodifiable(savedSubscriptions);

  @override
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    if (failWrites) throw StateError('Test write failure');
    savedSubscriptions = List.of(subscriptions);
  }

  @override
  Future<void> clearSubscriptions() async {
    savedSubscriptions = [];
  }

  @override
  Future<String?> loadProfileName() async => profileName;

  @override
  Future<void> saveProfileName(String name) async {
    profileName = name;
  }
}

class _DelayedWriteRepository extends _MemorySubscriptionRepository {
  final List<Completer<void>> writeGates = [
    Completer<void>(),
    Completer<void>(),
  ];

  int _writeCount = 0;
  final Completer<void> secondWriteStarted = Completer<void>();

  @override
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final gate = writeGates[_writeCount++];
    if (_writeCount == 2) secondWriteStarted.complete();
    await gate.future;
    savedSubscriptions = List.of(subscriptions);
  }
}

Subscription _subscription(String id) => Subscription(
  id: id,
  name: 'Test subscription',
  amount: 150,
  billingCycle: BillingCycle.monthly,
  category: SubscriptionCategory.streaming,
  anchorDate: DateTime(2026, 10, 23),
  createdAt: DateTime(2026, 1, 1),
);
