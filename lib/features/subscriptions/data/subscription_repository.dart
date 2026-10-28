import '../domain/subscription.dart';

abstract interface class SubscriptionRepository {
  Future<List<Subscription>> loadSubscriptions();

  Future<void> saveSubscriptions(List<Subscription> subscriptions);

  Future<void> clearSubscriptions();

  Future<String?> loadProfileName();

  Future<void> saveProfileName(String name);
}
