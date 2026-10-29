import '../domain/reminder_settings.dart';

abstract interface class ReminderSettingsRepository {
  Future<ReminderSettings> load();

  Future<void> save(ReminderSettings settings);
}
