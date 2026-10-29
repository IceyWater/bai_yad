import '../domain/subscription.dart';

abstract interface class ReminderService {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> schedule(
    Iterable<Subscription> subscriptions, {
    required DateTime now,
    required int daysBefore,
  });

  Future<void> cancelAll();
}
