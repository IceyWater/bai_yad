import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/reminder_settings_provider.dart';
import '../application/subscription_providers.dart';
import '../domain/reminder_schedule.dart';
import '../domain/reminder_settings.dart';
import '../domain/subscription.dart';

class ReminderSettingsDialog extends ConsumerStatefulWidget {
  const ReminderSettingsDialog({required this.subscriptions, super.key});

  final List<Subscription> subscriptions;

  @override
  ConsumerState<ReminderSettingsDialog> createState() =>
      _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState
    extends ConsumerState<ReminderSettingsDialog> {
  bool _isWorking = false;
  String? _message;

  Future<void> _setEnabled(bool enabled, ReminderSettings settings) async {
    setState(() {
      _isWorking = true;
      _message = null;
    });
    try {
      final service = ref.read(reminderServiceProvider);
      if (enabled) {
        final granted = await service.requestPermission();
        if (!mounted) return;
        if (!granted) {
          setState(() {
            _message = 'Permission was not granted. Allow notifications in device settings, then try again.';
          });
          return;
        }
        await service.schedule(
          widget.subscriptions,
          now: DateTime.now(),
          daysBefore: settings.daysBefore,
        );
      } else {
        await service.cancelAll();
      }
      await ref
          .read(reminderSettingsControllerProvider.notifier)
          .updateSettings(enabled: enabled);
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Could not update reminders: $error');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _setLeadTime(int daysBefore, ReminderSettings settings) async {
    setState(() {
      _isWorking = true;
      _message = null;
    });
    try {
      await ref
          .read(reminderSettingsControllerProvider.notifier)
          .updateSettings(daysBefore: daysBefore);
      if (settings.enabled) {
        await ref
            .read(reminderServiceProvider)
            .schedule(
              widget.subscriptions,
              now: DateTime.now(),
              daysBefore: daysBefore,
            );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Could not update reminders: $error');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(reminderSettingsControllerProvider)
      .when(
        loading: () => const AlertDialog(
          content: SizedBox(
            height: 48,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.mint),
            ),
          ),
        ),
        error: (error, _) => AlertDialog(
          title: const Text('Renewal reminders'),
          content: Text('Reminder settings could not be loaded: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
        data: (settings) => _buildDialog(settings),
      );

  Widget _buildDialog(ReminderSettings settings) => AlertDialog(
    title: const Text('Renewal reminders'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get a local alert before a subscription renews.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Reminders',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                key: const Key('reminderEnabledSwitch'),
                value: settings.enabled,
                onChanged: _isWorking
                    ? null
                    : (value) => _setEnabled(value, settings),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 4),
            Text(
              _message!,
              style: const TextStyle(
                color: AppColors.warningText,
                fontSize: 12,
              ),
            ),
          ],
          const Divider(height: 24),
          const Text(
            'Remind me',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SegmentedButton<int>(
            segments: [
              for (final days in supportedReminderLeadTimes)
                ButtonSegment(
                  value: days,
                  label: Text('$days day${days == 1 ? '' : 's'}'),
                ),
            ],
            selected: {settings.daysBefore},
            onSelectionChanged: _isWorking
                ? null
                : (selection) => _setLeadTime(selection.first, settings),
          ),
          if (_isWorking) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isWorking ? null : () => Navigator.pop(context),
        child: const Text('Done'),
      ),
    ],
  );
}
