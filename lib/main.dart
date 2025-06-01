import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/config/env_config.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:mads_safebox/services/background_service.dart';
import 'package:mads_safebox/services/category_box_service.dart';
import 'package:mads_safebox/widgets/auth_wrapper.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

  await initializeService();
  await CategoryBoxService.init();
  await Permission.notification.request();

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
