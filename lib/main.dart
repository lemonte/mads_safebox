import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/config/env_config.dart';
import 'package:mads_safebox/firebase_options.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:mads_safebox/services/category_box_service.dart';
import 'package:mads_safebox/services/firebase_messaging.dart';
import 'package:mads_safebox/services/user_box_service.dart';
import 'package:mads_safebox/services/workmanager.dart';
import 'package:mads_safebox/widgets/auth_wrapper.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initialize() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await EnvConfig().initialize();

    await Supabase.initialize(
      url: EnvConfig().supabaseUrl,
      anonKey: EnvConfig().supabaseAnonKey,
    );

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
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
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final filePath = response.payload;
        if (filePath != null) {
          OpenFile.open(filePath);
        }
      },
    );

    Workmanager().initialize(
      callbackDispatcher,
      //isInDebugMode: true,
      // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
    );

    Workmanager().registerPeriodicTask(
      keyWorkManagerAutoSync,
      taskWorkManagerAutoSync,
      frequency: durationSyncRetry,
      //initialDelay: const Duration(seconds: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
        //requiresDeviceIdle: true,
      ),
    );

    await UserBoxService.init();
    await CategoryBoxService.init();
    await Permission.notification.request();
    await initFirebaseMessaging();
  } catch (e) {
    debugPrint("Error initializing: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeBox',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: mainColor,
        cardColor: Colors.white,
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey.shade300;
            }
            if (states.contains(WidgetState.selected)) {
              return mainColor;
            }
            if (states.contains(WidgetState.pressed)) {
              return Colors.grey.shade100;
            }
            return Colors.white;
          }),
          checkColor: WidgetStateProperty.all(mainTextColor),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
