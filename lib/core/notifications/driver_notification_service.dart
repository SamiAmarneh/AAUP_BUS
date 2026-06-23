import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/bus_company/data/driver_repository.dart';
import 'notification_constants.dart';

class DriverNotificationService {
  DriverNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    DriverRepository? driverRepository,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _driverRepository = driverRepository ?? DriverRepository();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final DriverRepository _driverRepository;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  String? _activeDriverUid;
  bool _isInitialized = false;

  Future<void> startForDriver(String driverUid) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final trimmedUid = driverUid.trim();
    if (trimmedUid.isEmpty) {
      return;
    }

    if (_activeDriverUid == trimmedUid && _isInitialized) {
      await _syncToken(trimmedUid);
      return;
    }

    await stop();
    _activeDriverUid = trimmedUid;
    await _initializeLocalNotifications();
    await _requestPermissions();
    await _syncToken(trimmedUid);
    _listenForTokenRefresh(trimmedUid);
    _listenForForegroundMessages();
    _isInitialized = true;
  }

  Future<void> stop() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _activeDriverUid = null;
    _isInitialized = false;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    const channel = AndroidNotificationChannel(
      NotificationConstants.driverBookingChannelId,
      NotificationConstants.driverBookingChannelName,
      description: NotificationConstants.driverBookingChannelDescription,
      importance: Importance.high,
    );

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission();
    await Permission.notification.request();
  }

  Future<void> _syncToken(String driverUid) async {
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) {
      return;
    }

    await _driverRepository.saveFcmToken(
      driverUid: driverUid,
      token: token,
    );
  }

  void _listenForTokenRefresh(String driverUid) {
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) async {
        await _driverRepository.saveFcmToken(
          driverUid: driverUid,
          token: token,
        );
      },
    );
  }

  void _listenForForegroundMessages() {
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      (message) async {
        await _showForegroundNotification(message);
      },
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      NotificationConstants.driverBookingChannelId,
      NotificationConstants.driverBookingChannelName,
      channelDescription: NotificationConstants.driverBookingChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails),
      payload: message.data.toString(),
    );
  }
}
