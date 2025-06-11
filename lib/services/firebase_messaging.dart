import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart';

Future<void> initFirebaseMessaging() async {
  await Firebase.initializeApp();

  await FirebaseMessaging.instance.requestPermission(
      sound: true,
      announcement: true,
      alert: true,
      providesAppNotificationSettings: true);

  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint("\nMessage Data: ${message.data}\n");

    if (message.notification != null) {
      debugPrint(
          'Message also contained a notification: ${message.notification!.body}');
      await handleFCMMessage(message);
    }
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");
  debugPrint('Message data: ${message.data}');

  if (message.notification != null) {
    await handleFCMMessage(message);
  }
}

Future<void> handleFCMMessage(RemoteMessage message) async {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = await initNotificationsPlugin();

  flutterLocalNotificationsPlugin.show(int.parse(message.data['fileId']), message.notification!.title,
      message.notification!.body, fcmNotificationDetails, payload: message.data['path']);
}

Future<void> updateFCMToken(UserSB user) async {
  // Get and save FCM token
  String? token = await FirebaseMessaging.instance.getToken();
  debugPrint("FCM Token: $token");

  // Save to Supabase
  if (token != null) {
    await Supabase.instance.client
        .from('users')
        .update({'fcm_token': token}).eq('id', user.id);
  }
}

