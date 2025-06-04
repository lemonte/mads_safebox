import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mads_safebox/models/category.dart';

CategorySB defaultCategory = CategorySB(id: 1, createdAt: DateTime.now(), uid: null, name: "My Files");
const Color mainColor = Color(0xFF003366);
const Color mainTextColor = Color(0xFFFFFFFF);
const Color snackBarColor = Color(0xFF8C8C8C);
const String usersBoxKey = "UserData";
const String categoryBoxKey = "FavoriteCategories";
const bgServiceNotificationChannelId = 'SynchronizationService';
const durationSyncRetry = Duration(minutes: 30);
const String dateFormatToSupabase = 'yyyy-MM-dd';
const String dateFormatToDisplay = 'dd/MM/yyyy';

const serviceNotificationDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    bgServiceNotificationChannelId,
    'SafeBox Synchronization Service',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    icon: '@mipmap/launcher_icon',
  ),
);