import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/logger.dart';
import '../../game/engine/notification_planner.dart';

/// Local (on-device) reminders. No server or push token is involved.
abstract class NotificationService {
  Future<void> initialize();

  /// Shows the OS permission prompt. Returns whether notifications are allowed.
  Future<bool> requestPermission();
  Future<void> schedule(List<PlannedReminder> reminders);
  Future<void> cancelAll();
}

class NoopNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {}
  @override
  Future<void> cancelAll() async {}
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'base_status',
    '基地の状況',
    channelDescription: '保管庫の満杯や放置報酬の上限をお知らせします',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: 'ic_stat_orbit',
  );

  @override
  Future<void> initialize() async {
    try {
      // Reminders are scheduled as absolute instants, so UTC is sufficient.
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_orbit'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e, st) {
      log.error('Notification init failed', e, st);
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final a = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await a?.requestNotificationsPermission() ?? false;
      }
      final i = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await i?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e, st) {
      log.error('Notification permission request failed', e, st);
      return false;
    }
  }

  @override
  Future<void> schedule(List<PlannedReminder> reminders) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final now = tz.TZDateTime.now(tz.UTC);
      for (final r in reminders) {
        await _plugin.zonedSchedule(
          id: r.kind.index,
          title: r.title,
          body: r.body,
          scheduledDate: now.add(r.delay),
          notificationDetails: const NotificationDetails(
            android: _channel,
            iOS: DarwinNotificationDetails(),
          ),
          // Inexact is fine for these reminders and needs no exact-alarm permission.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e, st) {
      log.error('Scheduling notifications failed', e, st);
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e, st) {
      log.error('Cancelling notifications failed', e, st);
    }
  }
}
