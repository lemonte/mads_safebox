import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/file.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snack_bar.dart';
import '../widgets/loading.dart';

Future<void> downloadFileShared({
  required BuildContext context,
  required FileSB fileSB,
  required Map<String, Uint8List> downloadedFiles,
  required Future<Uint8List?> Function(String path) fetchFile,
  required FlutterLocalNotificationsPlugin notificationsPlugin,
  required bool showNotification,
}) async {
  try {
    final authService = AuthService();
    final directory = await getDownloadsDirectory();
    final userId = authService.getCurrentUser().id;

    final targetDirPath =
        "${directory!.path}/$userId/${fileSB.path.split("/").first}";
    final fileFullPath = "$targetDirPath/${fileSB.path.split("/").last}";
    final file = File(fileFullPath);

    if (await file.exists()) {
      if (!context.mounted) return;
      if (showNotification) {
        showCustomSnackBar(context, "O arquivo '${fileSB.name}' já existe.");
      }
      return;
    }

    // Busca arquivo se não estiver no cache
    if (!downloadedFiles.containsKey(fileSB.name)) {
      Uint8List? fileData = await fetchFile(fileSB.path);
      if (fileData != null) {
        downloadedFiles[fileSB.name] = fileData;
      } else {
        throw Exception("Falha ao buscar o arquivo");
      }
    }

    await Directory(targetDirPath).create(recursive: true);
    await file.writeAsBytes(downloadedFiles[fileSB.name]!);

    if (showNotification) {
      final permissionGranted = await Permission.notification.request().isGranted;
      if (permissionGranted) {
        await notificationsPlugin.show(
          0,
          'Download concluído',
          fileSB.name,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'download_channel',
              'Downloads',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              icon: '@mipmap/launcher_icon',
            ),
          ),
          payload: fileFullPath,
        );
      }
      if (context.mounted) {
        showCustomSnackBar(context, "File downloaded");
      }
    }
  } catch (e) {
    debugPrint("Error downloading file: $e");
    if (showNotification && context.mounted) {
      showCustomSnackBar(context, "Error downloading file");
    }
  }
}

void showDownloadingDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Downloading File"),
              SizedBox(height: 8),
              Loading(),
            ],
          ),
        ),
      );
    },
  );
}

Future<Uint8List?> tryLoadDownloadedFileSB(FileSB fileSB) async {
  final userId = AuthService().getCurrentUser().id;
  final directory = await getDownloadsDirectory();
  final filePath =
      "${directory!.path}/$userId/${fileSB.path.split("/").first}/${fileSB.path.split("/").last}";
  return tryLoadDownloadedFile(path: filePath);
}

Future<Uint8List?> tryLoadDownloadedFile({
  required String path,
}) async {
  final file = File(path);
  if (await file.exists()) {
    return await file.readAsBytes();
  }
  return null;
}

PopupMenuItem buildDownloadMenuItem({
  required BuildContext context,
  required FileSB fileSB,
  required Map<String, Uint8List> downloadedFiles,
  required Future<Uint8List?> Function(String path) fetchFile,
  required FlutterLocalNotificationsPlugin notificationsPlugin,
}) {
  return PopupMenuItem(
    child: const Text("Download", style: TextStyle(color: Colors.black)),
    onTap: () async {
      await downloadFileShared(
        context: context,
        fileSB: fileSB,
        downloadedFiles: downloadedFiles,
        fetchFile: fetchFile,
        notificationsPlugin: notificationsPlugin,
        showNotification: true,
      );
    },
  );
}

