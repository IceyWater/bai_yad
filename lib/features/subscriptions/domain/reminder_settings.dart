import 'reminder_schedule.dart';

class ReminderSettings {
  const ReminderSettings({this.enabled = false, this.daysBefore = 3});

  final bool enabled;
  final int daysBefore;

  ReminderSettings copyWith({bool? enabled, int? daysBefore}) {
    final leadTime = daysBefore ?? this.daysBefore;
    if (!supportedReminderLeadTimes.contains(leadTime)) {
      throw ArgumentError.value(leadTime, 'daysBefore');
    }
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      daysBefore: leadTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.daysBefore == daysBefore;

  @override
  int get hashCode => Object.hash(enabled, daysBefore);
}
