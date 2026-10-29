import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reminder_schedule.dart';
import '../domain/reminder_settings.dart';
import 'reminder_settings_repository.dart';

class SharedPreferencesReminderSettingsRepository
    implements ReminderSettingsRepository {
  static const _enabledKey = 'reminders.enabled.v1';
  static const _daysBeforeKey = 'reminders.daysBefore.v1';

  @override
  Future<ReminderSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedDaysBefore = preferences.getInt(_daysBeforeKey);
    return ReminderSettings(
      enabled: preferences.getBool(_enabledKey) ?? false,
      daysBefore: supportedReminderLeadTimes.contains(savedDaysBefore)
          ? savedDaysBefore!
          : 3,
    );
  }

  @override
  Future<void> save(ReminderSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    final savedEnabled = await preferences.setBool(
      _enabledKey,
      settings.enabled,
    );
    final savedDaysBefore = await preferences.setInt(
      _daysBeforeKey,
      settings.daysBefore,
    );
    if (!savedEnabled || !savedDaysBefore) {
      throw StateError('The device rejected the reminder settings write.');
    }
  }
}
