import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/subscription.dart';
import 'subscription_repository.dart';

class SharedPreferencesSubscriptionRepository
    implements SubscriptionRepository {
  static const _subscriptionsKey = 'subscriptions.v1';
  static const _profileNameKey = 'profile.name.v1';

  @override
  Future<List<Subscription>> loadSubscriptions() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_subscriptionsKey);
    if (rawValue == null) return [];

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! List) {
        throw const FormatException('Expected a list of subscriptions.');
      }
      return decoded
          .map(
            (value) =>
                Subscription.fromJson(Map<String, Object?>.from(value as Map)),
          )
          .toList(growable: false);
    } on FormatException catch (error) {
      throw CorruptSubscriptionDataException(
        'Saved subscription data is invalid: ${error.message}',
      );
    } on TypeError catch (error) {
      throw CorruptSubscriptionDataException(
        'Saved subscription data has an invalid shape: $error',
      );
    } on ArgumentError catch (error) {
      throw CorruptSubscriptionDataException(
        'Saved subscription data contains an unknown value: ${error.message}',
      );
    }
  }

  @override
  Future<void> saveSubscriptions(List<Subscription> subscriptions) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _subscriptionsKey,
      jsonEncode(
        subscriptions.map((subscription) => subscription.toJson()).toList(),
      ),
    );
    if (!saved) {
      throw StateError('The device rejected the subscription data write.');
    }
  }

  @override
  Future<void> clearSubscriptions() async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(_subscriptionsKey);
    if (!removed && preferences.containsKey(_subscriptionsKey)) {
      throw StateError('The saved subscription data could not be cleared.');
    }
  }

  @override
  Future<String?> loadProfileName() async {
    final preferences = await SharedPreferences.getInstance();
    final name = preferences.getString(_profileNameKey)?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  @override
  Future<void> saveProfileName(String name) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(_profileNameKey, name.trim());
    if (!saved) {
      throw StateError('The device rejected the profile name write.');
    }
  }
}

class CorruptSubscriptionDataException implements Exception {
  const CorruptSubscriptionDataException(this.message);

  final String message;

  @override
  String toString() => message;
}
