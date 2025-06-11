import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mads_safebox/models/category.dart';

CategorySB defaultCategory = CategorySB(id: 1, createdAt: DateTime.now(), uid: null, name: "My Files");
const Color mainColor = Color(0xFF003366);
const Color mainTextColor = Color(0xFFFFFFFF);
const Color snackBarColor = Color(0xFF8C8C8C);
const String usersBoxKey = "UserData";
const String categoryBoxKey = "FavoriteCategories";
const durationSyncRetry = Duration(minutes: 30);
const String dateFormatToSupabase = 'yyyy-MM-dd';
const String dateFormatToDisplay = 'dd/MM/yyyy';

const autoSyncNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    "SafeBoxSynchronization",      //channel ID
    'SafeBox Synchronization Channel',    //channel name
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: '@mipmap/launcher_icon',
  ),
);

const fcmNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    "SafeBoxFCM",      //channel ID
    'SafeBox FCM Notifications Channel',    //channel name
    importance: Importance.high,
    priority: Priority.max,
    playSound: true,
    icon: '@mipmap/launcher_icon',
  ),
);

//WorkManager Keys
const String keyWorkManagerAutoSync = "autoSyncSafeBox";
const String taskWorkManagerAutoSync = "autoSyncSafeBoxTask";

Future<FlutterLocalNotificationsPlugin> initNotificationsPlugin() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/launcher_icon');
  const initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    /*
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final filePath = response.payload;
      if (filePath != null) {
        OpenFile.open(filePath);
      }
    },
     */
  );

  return flutterLocalNotificationsPlugin;
}