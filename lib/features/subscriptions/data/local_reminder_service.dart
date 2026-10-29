import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../application/reminder_service.dart';
import '../domain/reminder_schedule.dart';
import '../domain/subscription.dart';

final class LocalReminderService implements ReminderService {
  LocalReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'renewal_reminders';
  static const _channelName = 'Renewal reminders';
  static const _channelDescription = 'Alerts before subscription renewals';

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;
  Future<void> _pendingOperations = Future<void>.value();

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    final initialized = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized != true) {
      throw StateError('Local notifications could not be initialized.');
    }
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> schedule(
    Iterable<Subscription> subscriptions, {
    required DateTime now,
    required int daysBefore,
  }) => _enqueue(() async {
    await initialize();
    await _plugin.cancelAll();

    final plan = buildReminderPlan(
      subscriptions,
      now: now,
      daysBefore: daysBefore,
    );
    for (final reminder in plan) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: 'Renewal coming up',
        body: '${reminder.subscription.name} renews in $daysBefore days.',
        scheduledDate: timezone.TZDateTime.from(
          reminder.notifyAt,
          timezone.local,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  });

  @override
  Future<void> cancelAll() => _enqueue(() async {
    await initialize();
    await _plugin.cancelAll();
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pendingOperations.then((_) => operation());
    _pendingOperations = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }
}
