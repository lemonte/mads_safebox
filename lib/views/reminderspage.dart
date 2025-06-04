import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/services/sharefiles_service.dart';
import 'package:mads_safebox/views/filepage.dart';
import 'package:mads_safebox/widgets/expire_date_change_modal.dart';
import 'package:mads_safebox/widgets/loading.dart';
import 'package:mads_safebox/widgets/custom_appbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/file.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../widgets/custom_snack_bar.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  FileService fileService = FileService();
  ShareFilesService shareFilesService = ShareFilesService();
  bool isShowingImages = true;

  Map<String, Uint8List> downloadedFiles = {};

  //late Future<List<SharedFileSB>> sharedFiles;
  // late Stream<List<FileSB>?> images;
  // late Stream<List<FileSB>?> docs;

  Future<List<FileSB>> getSharedFiles() async {
    return await fileService.getExpiringFiles();
  }

  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> downloadFile(FileSB fileSB, bool notifications) async {
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
          "${directory!.path}/$userId/${fileSB.path.split("/").first}";
      debugPrint("targetDirPath: $targetDirPath");

      final fileFullPath = "$targetDirPath/${fileSB.path.split("/").last}";
      debugPrint("fileFullPath: $fileFullPath");

      await Directory(targetDirPath).create(recursive: true);
      final filePath = fileFullPath;
      final file = File(filePath);

      if (await file.exists()) {
        if (!mounted) return;
        notifications
            ? showCustomSnackBar(
                context, "O arquivo '${fileSB.name}' já existe.")
            : null;
        return;
      }

      // await requestStoragePermission();

      if (!downloadedFiles.containsKey(fileSB.name)) {
        Uint8List? file = await fileService.getFile(fileSB.path);
        downloadedFiles[fileSB.name] = file!;
      }

      await file.writeAsBytes(downloadedFiles[fileSB.name]!);
      debugPrint("File downloaded to: ${file.path}");

      if (notifications) {
        // Mostra notificação de download
        await Permission.notification.request().isGranted
            ? await flutterLocalNotificationsPlugin.show(
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
                payload: filePath,
              )
            : null;
      }
      if (!mounted) return;
      notifications ? showCustomSnackBar(context, "File downloaded") : null;
    } catch (e) {
      debugPrint("Error downloading file: $e");
      notifications
          ? showCustomSnackBar(context, "Error downloading file")
          : null;
    }
  }

  @override
  void initState() {
    super.initState();
    // sharedFiles = shareFilesService.getSharedFiles();
    // images = fileService.getImageList();
    // docs = fileService.getDocList();
  }

  TextEditingController renameController = TextEditingController();

  @override
  void dispose() {
    renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(true),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            "Files with an Expire Date",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            //height: 500,
            child: buildFileList(),
          ),
        ],
      ),
    );
  }

  void navigateToFilePage(Uint8List fileBytes, FileSB fileSB) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePage(fileSB: fileSB, file: fileBytes),
      ),
    );
  }

  void showDownloadingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  FutureBuilder<List<FileSB>> buildFileList() {
    return FutureBuilder<List<FileSB>>(
      future: getSharedFiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loading());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading files."));
        } else {
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No files found."));
          }
          return ListView(
            children: [
              for (int i = 0; i < snapshot.data!.length; i++)
                ListTile(
                  //TODO: implementar o menu (mudar o on tap para a row do icon e imagem)
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 4,
                        child: GestureDetector(
                          onTap: () async {
                            if (downloadedFiles
                                .containsKey(snapshot.data![i].name)) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FilePage(
                                        fileSB: snapshot.data![i],
                                        file: downloadedFiles[
                                            snapshot.data![i].name]!),
                                  ));
                              return;
                            }

                            try {
                              AuthService authService = AuthService();
                              Directory? directory;
                              directory = await getDownloadsDirectory();
                              final userId = authService.getCurrentUser().id;
                              final targetDirPath =
                                  "${directory!.path}/$userId/${snapshot.data![i].path.split("/").first}";
                              final fileFullPath =
                                  "$targetDirPath/${snapshot.data![i].path.split("/").last}";
                              final filePath = fileFullPath;
                              final downloadedFile = File(filePath);
                              if (await downloadedFile.exists()) {
                                final fileBytes =
                                    await downloadedFile.readAsBytes();
                                if (!mounted) return;
                                navigateToFilePage(
                                    fileBytes, snapshot.data![i]);
                                return;
                              }
                            } on Exception catch (e) {
                              debugPrint("Error checking downloaded file: $e");
                            }

                            if (!mounted) return;
                            showDownloadingDialog();
                            Uint8List? file = await fileService
                                .getFile(snapshot.data![i].path);

                            debugPrint(snapshot.data![i].path);

                            if (context.mounted) {
                              Navigator.pop(context);

                              if (file == null) {
                                showCustomSnackBar(
                                    context, 'Could not download the file');
                                return;
                              }

                              downloadedFiles[snapshot.data![i].name] = file;

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FilePage(
                                        fileSB: snapshot.data![i], file: file),
                                  ));
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: Icon(Icons.image),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      snapshot.data![i].name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "Expire date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(snapshot.data![i].expireDate.toString()))}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: PopupMenuButton(
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.black,
                          ),
                          itemBuilder: (BuildContext context) {
                            return getButtonList(snapshot.data![i]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  List<PopupMenuItem> getButtonList(FileSB fileSB) {
    return [
      PopupMenuItem(
        child: const Text("Change Expire Date",
            style: TextStyle(color: Colors.black)),
        onTap: () async {
          showDialog(
              context: context,
              builder: (context) {
                return ExpireDateChangeModal(fileSB: fileSB);
              }).whenComplete(() {
            setState(() {});
          });
        },
      ),
      PopupMenuItem(
        child: const Text("Download", style: TextStyle(color: Colors.black)),
        onTap: () async {
          await downloadFile(fileSB, true);
        },
      ),
    ];
  }
}
