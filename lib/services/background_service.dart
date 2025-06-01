import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mads_safebox/global/bg_service_invokes.dart';
import 'package:mads_safebox/models/file.dart';
import 'package:mads_safebox/services/file_service.dart';
import 'package:mads_safebox/services/user_box_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import '../global/default_values.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'SynchronizationService', // id
    'SafeBox Synchronization Service', // title
    description:
        'This channel is used to synchronize downloaded files in the device with those on the cloud.', // description
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  ///meter a imagem com o fundo transparente
  const initializationSettingsAndroid =
      AndroidInitializationSettings('ic_bg_service_small');
  const initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,

      notificationChannelId: bgServiceNotificationChannelId,
      initialNotificationTitle: 'SafeBox Synchronization Service',
      initialNotificationContent: 'Synchronizing files with the cloud',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

///
/// iOS service
/// REMINDER: is not "continuous" like in android, may stop after 15 or 30 seconds
///
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

///
/// Android
///
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await EnvConfig().initialize();

  await Supabase.initialize(
    url: EnvConfig().supabaseUrl,
    anonKey: EnvConfig().supabaseAnonKey,
  );

  final FileService fileService = FileService();
  final UserBoxService userBoxService = UserBoxService();
  await userBoxService.init();

  service.on(invokeAddUser).listen((data) {
    if (data != null) {
      userBoxService.addUserData(data[userboxKeyUid], data[userboxKeyUsername]);
    }
  });
  service.on(invokeUpdateAutoSyncPreference).listen((data) {
    if (data != null) {
      userBoxService.updateAutoSyncPreference(
          data[userboxKeyUid], data[userboxKeyAutoSync]);
    }
  });
  service.on(invokeGetAutoSyncFromApp).listen((data) {
    if (data != null) {
      bool autoSyncValue = userBoxService.getAutoSync(data[userboxKeyUid]);
      service.invoke(
          invokeRespondWithAutoSyncToApp, {userboxKeyAutoSync: autoSyncValue});
    }
  });

  service.on(invokeUpdateDownloadWithMobileData).listen((data) {
    if (data != null) {
      userBoxService.updateAllowDownloadWithMobileData(
          data[userboxKeyUid], data[userboxKeyDownloadWithMobileData]);
    }
  });
  service.on(invokeGetDownloadWithMobileDataFromApp).listen((data) {
    if (data != null) {
      bool downloadWithMobileDataValue =
          userBoxService.getAllowDownloadWithMobileData(data[userboxKeyUid]);
      service.invoke(invokeRespondWithDownloadWithMobileDataToApp,
          {userboxKeyDownloadWithMobileData: downloadWithMobileDataValue});
    }
  });

  service.on(invokeSynchronize).listen((data) {
    checkSyncTimer(
        userBoxService, flutterLocalNotificationsPlugin, fileService, service);
  });

  //initialize every time
  checkSyncTimer(
      userBoxService, flutterLocalNotificationsPlugin, fileService, service);
}

void checkSyncTimer(
    UserBoxService userBoxService,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    FileService fileService,
    ServiceInstance service) {
  Timer.periodic(
    //mudar para uns minutos para tentar nao acontecer durante a utilização da app
    durationSyncRetry,
    (timer) async {
      bool retry = await syncFilesWithCloud(
          userBoxService, flutterLocalNotificationsPlugin, fileService);
      if (retry) {
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "SafeBox Synchronization Service",
            content:
                "Couldn't synchronize all files, retrying in ${durationSyncRetry.inMinutes}min.",
          );
        }
      } else {
        if (service is AndroidServiceInstance) {
          String dateNow = DateTime.now().toString().split('.').first;
          service.setForegroundNotificationInfo(
            title: "SafeBox Synchronization Service",
            content: "Files synchronized with the cloud at \n$dateNow.",
          );
        }
        timer.cancel();
      }
    },
  );
}

Future<bool> syncFilesWithCloud(
    UserBoxService userBoxService,
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    FileService fileService) async {
  bool retry = false;
  int notificationId = 1;

  for (var uid in userBoxService.getUsers()) {
    if (!userBoxService.getAutoSync(uid)) {
      continue;
    }

    List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    String username = userBoxService.getUsername(uid);

    if (!connectivityResult.contains(ConnectivityResult.wifi)) {
      if (connectivityResult.contains(ConnectivityResult.mobile)) {
        if (!userBoxService.getAllowDownloadWithMobileData(uid)) {
          flutterLocalNotificationsPlugin.show(
            notificationId,
            'SafeBox Synchronization',
            'No connection according to $username\'s preferences.',
            serviceNotificationDetails,
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
      serviceNotificationDetails,
    );
    List<FileSB> cloudFileList;
    try {
      cloudFileList = await fileService.getAllFilesList(uid);
    } catch (e) {
      flutterLocalNotificationsPlugin.show(
        notificationId,
        'SafeBox Synchronization',
        'Could not synchronize files for: $username',
        serviceNotificationDetails,
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
      serviceNotificationDetails,
    );
    notificationId++;
  }
  return retry;
}
