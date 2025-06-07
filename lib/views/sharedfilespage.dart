import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:mads_safebox/models/sharedplusfile.dart';
import 'package:mads_safebox/services/sharefiles_service.dart';
import 'package:mads_safebox/views/filepage.dart';
import 'package:mads_safebox/widgets/loading.dart';
import 'package:mads_safebox/widgets/custom_appbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../global/download_utils.dart';
import '../models/file.dart';
import '../models/role.dart';
import '../models/shared.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../widgets/custom_snack_bar.dart';

class SharedFilesPage extends ConsumerStatefulWidget {
  const SharedFilesPage({super.key});

  @override
  ConsumerState<SharedFilesPage> createState() => _SharedFilesState();
}

class _SharedFilesState extends ConsumerState<SharedFilesPage> {
  FileService fileService = FileService();
  ShareFilesService shareFilesService = ShareFilesService();
  bool isShowingImages = true;

  Map<String, Uint8List> downloadedFiles = {};

  //late Future<List<SharedFileSB>> sharedFiles;
  late Stream<List<FileSB>?> images;
  late Stream<List<FileSB>?> docs;

  Future<List<SharedFileSB>> getSharedFiles() async {
    List<SharedFileSB> sharedFiles = await shareFilesService.getSharedFiles();
    return await fileService.getSharedFiles(sharedFiles);
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
      Directory? directory = await getDownloadsDirectory();
      debugPrint("download directory: $directory");

      final userId = authService.getCurrentUser().id;
      final targetDirPath =
          "${directory!.path}/$userId/${fileSB.path.split("/").first}";
      final fileFullPath = "$targetDirPath/${fileSB.path.split("/").last}";
      final file = File(fileFullPath);

      if (await file.exists()) {
        if (!mounted) return;
        if (notifications) {
          showCustomSnackBar(context, "O arquivo '${fileSB.name}' já existe.");
        }
        return;
      }

      if (!downloadedFiles.containsKey(fileSB.name)) {
        Uint8List? downloaded = await fileService.getFile(fileSB.path);
        if (downloaded != null) downloadedFiles[fileSB.name] = downloaded;
      }

      await Directory(targetDirPath).create(recursive: true);
      await file.writeAsBytes(downloadedFiles[fileSB.name]!);

      if (notifications) {
        if (await Permission.notification.request().isGranted) {
          await flutterLocalNotificationsPlugin.show(
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
        if (mounted) {
          showCustomSnackBar(context, "File downloaded");
        }
      }
    } catch (e) {
      debugPrint("Error downloading file: $e");
      if (notifications && mounted) {
        showCustomSnackBar(context, "Error downloading file");
      }
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
            "Files Shared With You",
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

  void navigateToFilePage(
      Uint8List fileBytes, FileSB fileSB, SharedSB sharedSB) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FilePage(fileSB: fileSB, sharedSB: sharedSB, file: fileBytes),
      ),
    );
  }

  FutureBuilder<List<SharedFileSB>> buildFileList() {
    return FutureBuilder<List<SharedFileSB>>(
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
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 4,
                        child: GestureDetector(
                          onTap: () async {
                            if (downloadedFiles
                                .containsKey(snapshot.data![i].fileSB.name)) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FilePage(
                                        fileSB: snapshot.data![i].fileSB,
                                        sharedSB: snapshot.data![i].sharedSB,
                                        file: downloadedFiles[
                                            snapshot.data![i].fileSB.name]!),
                                  ));
                              return;
                            }
                            if (!mounted) return;
                            showDownloadingDialog(context);
                            try {
                              final fileBytes = await tryLoadDownloadedFileSB(snapshot.data![i].fileSB);
                              if (fileBytes != null) {
                                if (!mounted) return;
                                navigateToFilePage(
                                  fileBytes,
                                  snapshot.data![i].fileSB,
                                  snapshot.data![i].sharedSB,
                                );
                                return;
                              }
                            } catch (e) {
                              debugPrint("Error checking downloaded file: $e");
                            }


                            Uint8List? file = await fileService.getSharedFile(
                                snapshot.data![i].fileSB.path,
                                snapshot.data![i].sharedSB.uid);

                            debugPrint(snapshot.data![i].fileSB.path);

                            if (context.mounted) {
                              Navigator.pop(context);

                              if (file == null) {
                                showCustomSnackBar(
                                    context, 'Could not download the file');
                                return;
                              }

                              downloadedFiles[snapshot.data![i].fileSB.name] =
                                  file;

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FilePage(
                                        fileSB: snapshot.data![i].fileSB,
                                        sharedSB: snapshot.data![i].sharedSB,
                                        file: file),
                                  ));
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.0),
                                child: Icon(Icons
                                    .image),
                              ),
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      snapshot.data![i].fileSB.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "Expire date: ${DateFormat(dateFormatToDisplay).format(DateTime.parse(snapshot.data![i].sharedSB.expireDate.toString()))}",
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
                      Visibility(
                        visible:
                            snapshot.data![i].sharedSB.role == Role.download,
                        child: Expanded(
                          child: PopupMenuButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.black,
                            ),
                            itemBuilder: (BuildContext context) {
                              return getButtonList(snapshot.data![i].fileSB,
                                  snapshot.data![i].sharedSB);
                            },
                          ),
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

  List<PopupMenuItem> getButtonList(FileSB fileSB, SharedSB sharedSB) {
    return [
      buildDownloadMenuItem(
        context: context,
        fileSB: fileSB,
        downloadedFiles: downloadedFiles,
        fetchFile: fileService.getFile,
        notificationsPlugin: flutterLocalNotificationsPlugin,
      ),
    ];
  }
}
