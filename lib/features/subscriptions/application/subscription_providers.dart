import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_preferences_subscription_repository.dart';
import '../data/subscription_repository.dart';
import '../domain/subscription.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SharedPreferencesSubscriptionRepository(),
);

final subscriptionControllerProvider =
    AsyncNotifierProvider<SubscriptionController, List<Subscription>>(
      SubscriptionController.new,
    );

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, String?>(ProfileController.new);

class SubscriptionController extends AsyncNotifier<List<Subscription>> {
  Future<void> _pendingWrites = Future<void>.value();

  SubscriptionRepository get _repository =>
      ref.read(subscriptionRepositoryProvider);

  @override
  Future<List<Subscription>> build() => _repository.loadSubscriptions();

  Future<void> add(Subscription subscription) async {
    await _update((current) => [subscription, ...current]);
  }

  Future<void> remove(Subscription subscription) async {
    await _update(
      (current) => current.where((item) => item.id != subscription.id).toList(),
    );
  }

  Future<void> clearCorruptData() async {
    await _repository.clearSubscriptions();
    state = const AsyncData([]);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.loadSubscriptions);
  }

  Future<void> _update(List<Subscription> Function(List<Subscription>) update) {
    final operation = _pendingWrites.then((_) => _updatePersisted(update));
    _pendingWrites = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  Future<void> _updatePersisted(
    List<Subscription> Function(List<Subscription>) update,
  ) async {
    final previous = state.requireValue;
    final updated = update(previous);
    state = AsyncData(updated);
    try {
      await _repository.saveSubscriptions(updated);
    } catch (error, stackTrace) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class ProfileController extends AsyncNotifier<String?> {
  SubscriptionRepository get _repository =>
      ref.read(subscriptionRepositoryProvider);

  @override
  Future<String?> build() => _repository.loadProfileName();

  Future<void> save(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Profile name cannot be empty.');
    }
    await _repository.saveProfileName(cleanName);
    state = AsyncData(cleanName);
  }
}
