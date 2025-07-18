import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/models/role.dart';
import 'package:mads_safebox/models/shared.dart';
import 'package:mads_safebox/services/auth_service.dart';
import 'package:mads_safebox/views/fullscreen_pdfviewer.dart';
import 'package:mads_safebox/widgets/custom_snack_bar.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../global/default_values.dart';
import '../services/file_service.dart';
import '../widgets/custom_appbar.dart';
import '../models/file.dart';
import '../widgets/sharefilemodal.dart';
import 'fullscreen_image_viewer.dart';

class FilePage extends StatefulWidget {
  final FileSB fileSB;
  final SharedSB? sharedSB;

  ///tou a passar o fileSB porque pode ser preciso para fazer a partilha (remover se nao for)
  final Uint8List file;
  const FilePage(
      {super.key, required this.fileSB, required this.file, this.sharedSB});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  FileService fileService = FileService();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> downloadFile() async {
    try {
      AuthService authService = AuthService();

      Directory? directory;
      // directory = await getApplicationDocumentsDirectory();
      // print("directory: $directory");
      directory = await getDownloadsDirectory();
      debugPrint("download directory: $directory");

      // directory = await getExternalStorageDirectory();
      // print("external directory: $directory");

      final userId = authService.getCurrentUser().id;
      final targetDirPath =
          "${directory!.path}/$userId/${widget.fileSB.path.split("/").first}";
      debugPrint("targetDirPath: $targetDirPath");
      final fileFullPath =
          "$targetDirPath/${widget.fileSB.path.split("/").last}";
      debugPrint("fileFullPath: $fileFullPath");

      await Directory(targetDirPath).create(recursive: true);
      final filePath = fileFullPath;
      final file = File(filePath);

      if (await file.exists()) {
        if (!mounted) return;
        showCustomSnackBar(
            context, "O arquivo '${widget.fileSB.name}' já existe.");
        return;
      }

      // await requestStoragePermission();

      await file.writeAsBytes(widget.file);
      await MediaScanner.loadMedia(path: file.path);
      debugPrint("File downloaded to: ${file.path}");

      if (await Permission.notification.request().isGranted) {
        // Mostra notificação de download
        await flutterLocalNotificationsPlugin.show(
          0,
          'Download concluído',
          widget.fileSB.name,
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
          payload: filePath, // Para abrir o arquivo depois
        );
      }
      if (!mounted) return;
      showCustomSnackBar(context, "File downloaded");
    } catch (e) {
      debugPrint("Error downloading file: $e");
      showCustomSnackBar(context, "Error downloading file");
    }
  }

  Widget buildFileView() {
    if (widget.fileSB.extension != "pdf") {
      return Expanded(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullscreenImageViewer(imageData: widget.file),
                      ),
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Image.memory(
                        widget.file,
                        fit: BoxFit.contain,
                        width: constraints.maxWidth,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(widget.fileSB.name,
                      style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "Tap the image for FullScreen",
                    style: TextStyle(
                      fontSize: 20,
                      color: mainColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: Stack(
        children: [
          Center(child: SfPdfViewer.memory(widget.file)),
          Positioned(
            bottom: 40,
            right: 16,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FullscreenPdfViewer(pdfData: widget.file),
                  ),
                );
              },
              child: const Icon(Icons.fullscreen, color: mainColor, size: 40,),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(true),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                widget.sharedSB == null ||
                    widget.sharedSB?.role == Role.download
                    ? SizedBox(
                  width: 40,
                  child: IconButton(
                      onPressed: () async {
                        await downloadFile();
                      },
                      icon: const Icon(Icons.download, color: mainColor)),
                )
                    : const SizedBox(width: 40),
                const Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Your File",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return FileShareModal(fileSB: widget.fileSB);
                            });
                      },
                      icon: const Icon(Icons.share, color: mainColor)),
                )
              ],
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            Visibility(
              visible: widget.fileSB.expireDate != null,
              child: Text(
                "Expire date: ${DateFormat(dateFormatToDisplay).format(widget.fileSB.expireDate ?? DateTime.now())}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            buildFileView(),
          ],
        ),
      ),
    );
  }
}
