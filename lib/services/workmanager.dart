import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:mads_safebox/services/user_box_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../config/env_config.dart';
import '../models/file.dart';
import 'file_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskWorkManagerAutoSync) {
      await autoSync();
    }
    return Future.value(true);
  });
}

Future<void> autoSync() async {
  await EnvConfig().initialize();

  await Supabase.initialize(
    url: EnvConfig().supabaseUrl,
    anonKey: EnvConfig().supabaseAnonKey,
  );

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

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final FileService fileService = FileService();
  await UserBoxService.init();

  bool retry =
      await syncFilesWithCloud(flutterLocalNotificationsPlugin, fileService);

  if(!retry) {
    Workmanager().cancelByUniqueName(keyWorkManagerAutoSync);
  } else {
    flutterLocalNotificationsPlugin.show(
      9000,
      'SafeBox Synchronization',
      'Synchronization failed, retrying in ${durationSyncRetry.inMinutes} minutes.',
      autoSyncNotificationDetails,
    );
  }
}

Future<bool> syncFilesWithCloud(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    FileService fileService) async {
  bool retry = false;
  int notificationId = 1;

  List<String> uidList = UserBoxService.getUsers();

  for (var uid in uidList) {
    if (!UserBoxService.getAutoSync(uid)) {
      continue;
    }

    List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    String username = UserBoxService.getUsername(uid);

    if (!connectivityResult.contains(ConnectivityResult.wifi)) {
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        if (!UserBoxService.getAllowDownloadWithMobileData(uid)) {
          flutterLocalNotificationsPlugin.show(
            notificationId,
            'SafeBox Synchronization',
            'No connection according to $username\'s preferences.',
            autoSyncNotificationDetails,
          );
          retry = true;
          continue;
        }
      } else {
        retry = true;
        continue;
      }
    }

    flutterLocalNotificationsPlugin.show(
      notificationId,
      'SafeBox Synchronization',
      'Synchronizing files for user: $username',
      autoSyncNotificationDetails,
    );
    List<FileSB> cloudFileList;
    try {
      cloudFileList = await fileService.getAllFilesList(uid);
    } catch (e) {
      flutterLocalNotificationsPlugin.show(
        notificationId,
        'SafeBox Synchronization',
        'Could not synchronize files for: $username',
        autoSyncNotificationDetails,
      );
      notificationId++;
      retry = true;
      continue;
    }

    Directory? directory;
    for (FileSB fileSB in cloudFileList) {
      directory = await getDownloadsDirectory();
      final targetDirPath =
          "${directory!.path}/$uid/${fileSB.path.split("/").first}";
      final fileFullPath = "$targetDirPath/${fileSB.path.split("/").last}";
      await Directory(targetDirPath).create(recursive: true);
      final filePath = fileFullPath;
      final file = File(filePath);

      if (await file.exists()) {
        continue;
      }
      try {
        Uint8List? fileData = await fileService.getFile(fileSB.path);
        await file.writeAsBytes(fileData!);
      } catch (e) {
        debugPrint("Error downloading file: $e");
        retry = true;
        continue;
      }
    }

    String notificationText = !retry
        ? "Synchronized files for user: $username"
        : "Error synchronizing files for user: $username";
    flutterLocalNotificationsPlugin.show(
      notificationId,
      'SafeBox Synchronization',
      notificationText,
      autoSyncNotificationDetails,
    );
    notificationId++;
  }
  return retry;
}
