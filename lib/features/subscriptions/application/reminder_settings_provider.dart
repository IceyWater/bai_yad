import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reminder_settings_repository.dart';
import '../data/shared_preferences_reminder_settings_repository.dart';
import '../domain/reminder_settings.dart';

final reminderSettingsRepositoryProvider = Provider<ReminderSettingsRepository>(
  (ref) => SharedPreferencesReminderSettingsRepository(),
);

final reminderSettingsControllerProvider =
    AsyncNotifierProvider<ReminderSettingsController, ReminderSettings>(
      ReminderSettingsController.new,
    );

class ReminderSettingsController extends AsyncNotifier<ReminderSettings> {
  Future<void> _pendingWrites = Future<void>.value();

  ReminderSettingsRepository get _repository =>
      ref.read(reminderSettingsRepositoryProvider);

  @override
  Future<ReminderSettings> build() => _repository.load();

  Future<void> updateSettings({bool? enabled, int? daysBefore}) {
    final operation = _pendingWrites.then(
      (_) => _updatePersisted(enabled: enabled, daysBefore: daysBefore),
    );
    _pendingWrites = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  Future<void> _updatePersisted({bool? enabled, int? daysBefore}) async {
    final previous = state.requireValue;
    final updated = previous.copyWith(enabled: enabled, daysBefore: daysBefore);
    try {
      await _repository.save(updated);
      state = AsyncData(updated);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
