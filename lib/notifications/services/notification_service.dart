import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/services/api_client.dart';
import '../../core/services/storage_service.dart';
import '../models/notification_model.dart';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'sgd_notifications',
    'Notificaciones SGD',
    description: 'Notificaciones del Sistema de Gestión Documental',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  await localNotifications.initialize(
    settings: initSettings,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final notification = message.notification;
  final android = message.notification?.android;

  if (notification != null && android != null) {
    await localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  } else if (message.data.isNotEmpty) {
    final title = message.data['title'] ?? 'Nueva notificación';
    final body = message.data['message'] ?? message.data['body'] ?? '';
    await localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

class NotificationService extends ChangeNotifier {
  final ApiClient _apiClient;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  bool _initialized = false;

  String? _fcmToken;

  static const int _pageSize = 20;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sgd_notifications',
    'Notificaciones SGD',
    description: 'Notificaciones del Sistema de Gestión Documental',
    importance: Importance.high,
  );

  NotificationService(this._apiClient);

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  /// Initialize FCM and local notifications. Safe to call multiple times — runs only once.
  Future<void> initialize(StorageService storage) async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();

    final messaging = FirebaseMessaging.instance;

    // Request notification permission on Android 13+ / iOS
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('[NotificationService] Permission status: ${settings.authorizationStatus}');
    }

    // Get initial FCM token and register it
    try {
      final token = await messaging.getToken();
      if (token != null) {
        _fcmToken = token;
        await _registerToken(token, storage);
      }
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Failed to get FCM token: $e');
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      _fcmToken = newToken;
      await _registerToken(newToken, storage);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification open when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        print('[NotificationService] App opened from notification: ${message.messageId}');
      }
      loadNotifications(reset: true);
    });

    // Check if app was launched from a terminated-state notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('[NotificationService] App launched from notification: ${initialMessage.messageId}');
      }
      loadNotifications(reset: true);
    }

    // Load initial notifications
    await loadNotifications(reset: true);
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (kDebugMode) {
          print('[NotificationService] Notification tapped: ${details.payload}');
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('[NotificationService] Foreground message: ${message.messageId}');
    }

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } else if (message.data.isNotEmpty) {
      final title = message.data['title'] ?? 'Nueva notificación';
      final body = message.data['message'] ?? message.data['body'] ?? '';
      _localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }

    // Refresh the unread count and reload first page
    loadUnreadCount();
    loadNotifications(reset: true);
  }

  Future<void> _registerToken(String token, StorageService storage) async {
    try {
      await _apiClient.post(
        '/notifications/push-tokens',
        body: {'token': token, 'platform': 'ANDROID'},
      );
      if (kDebugMode) print('[NotificationService] FCM token registered: $token');
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Failed to register token: $e');
    }
  }

  /// Deregisters the current FCM token from the backend. Call on logout.
  Future<void> deregisterToken() async {
    final token = _fcmToken;
    if (token == null) return;
    try {
      await _apiClient.delete('/notifications/push-tokens/$token');
      if (kDebugMode) print('[NotificationService] FCM token deregistered');
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Failed to deregister token: $e');
    }
    _fcmToken = null;
    _initialized = false;
  }

  /// Loads a page of notifications. Pass [reset]=true to reload from page 0.
  Future<void> loadNotifications({bool reset = false}) async {
    if (_isLoading) return;
    if (!reset && !_hasMore) return;

    _isLoading = true;
    if (reset) {
      _page = 0;
      _hasMore = true;
    }
    notifyListeners();

    try {
      final response = await _apiClient.get(
        '/notifications?page=$_page&size=$_pageSize',
      );

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> content = decoded['content'] as List<dynamic>? ?? [];
      final bool last = decoded['last'] as bool? ?? true;

      final newItems = content
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (reset) {
        _notifications = newItems;
      } else {
        _notifications = [..._notifications, ...newItems];
      }

      _hasMore = !last;
      _page++;

      // Update unread count from loaded data
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      if (kDebugMode) print('[NotificationService] loadNotifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches just the unread count from the dedicated endpoint.
  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiClient.get('/notifications/unread-count');
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      _unreadCount = (decoded['count'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('[NotificationService] loadUnreadCount error: $e');
    }
  }

  /// Marks a single notification as read (PATCH /notifications/{id}/read).
  Future<void> markAsRead(String id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final wasUnread = !_notifications[index].isRead;
    if (!wasUnread) return;

    _notifications[index] = _notifications[index].copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
    _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
    notifyListeners();

    try {
      await _apiClient.patch('/notifications/$id/read');
    } catch (e) {
      if (kDebugMode) print('[NotificationService] markAsRead error: $e');
      // Revert on failure
      _notifications[index] = _notifications[index].copyWith(isRead: false, readAt: null);
      if (wasUnread) _unreadCount++;
      notifyListeners();
    }
  }

  /// Marks all notifications as read (POST /notifications/read-all).
  Future<void> markAllAsRead() async {
    final previousNotifications = List<NotificationModel>.from(_notifications);
    final previousCount = _unreadCount;

    // Optimistic update
    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true, readAt: DateTime.now()))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _apiClient.post('/notifications/read-all');
    } catch (e) {
      if (kDebugMode) print('[NotificationService] markAllAsRead error: $e');
      // Revert on failure
      _notifications = previousNotifications;
      _unreadCount = previousCount;
      notifyListeners();
    }
  }

  /// Resets the service state so it can be re-initialized after re-login.
  void reset() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _hasMore = true;
    _page = 0;
    _initialized = false;
    _fcmToken = null;
    notifyListeners();
  }
}
