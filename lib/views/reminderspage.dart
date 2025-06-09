
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:mads_safebox/services/sharefiles_service.dart';
import 'package:mads_safebox/views/filepage.dart';
import 'package:mads_safebox/widgets/expire_date_change_modal.dart';
import 'package:mads_safebox/widgets/loading.dart';
import 'package:mads_safebox/widgets/custom_appbar.dart';
import 'package:permission_handler/permission_handler.dart';

import '../global/download_utils.dart';
import '../models/file.dart';
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

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  TextEditingController renameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    renameController.dispose();
    super.dispose();
  }

  Future<List<FileSB>> getSharedFiles() async {
    return await fileService.getExpiringFiles();
  }

  Future<bool> requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    return false;
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
          Expanded(child: buildFileList()),
        ],
      ),
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
        } else if (snapshot.data!.isEmpty) {
          return const Center(child: Text("No files found."));
        } else {
          return ListView(
            children: snapshot.data!
                .map((file) => _buildFileTile(file))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildFileTile(FileSB fileSB) {
    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () => _handleFileTap(fileSB),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Icon(Icons.image),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fileSB.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          "Expire date: ${DateFormat(dateFormatToDisplay).format(DateTime.parse(fileSB.expireDate.toString()))}",
                          style: const TextStyle(color: Colors.grey),
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
              icon: const Icon(Icons.menu, color: Colors.black),
              itemBuilder: (_) => getButtonList(fileSB),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFileTap(FileSB fileSB) async {
    if (downloadedFiles.containsKey(fileSB.name)) {
      navigateToFilePage(downloadedFiles[fileSB.name]!, fileSB);
      return;
    }

    try {
      final fileBytes = await tryLoadDownloadedFileSB(fileSB);
      if (fileBytes != null) {
        if (!mounted) return;
        navigateToFilePage(
          fileBytes,
          fileSB,
        );
        return;
      }
    } catch (e) {
      debugPrint("Error checking downloaded file: $e");
    }

    if (!mounted) return;
    showDownloadingDialog(context);

    Uint8List? file = await fileService.getFile(fileSB.path);
    if (!mounted) return;
    Navigator.pop(context);

    if (file == null) {
      showCustomSnackBar(context, 'Could not download the file');
      return;
    }

    downloadedFiles[fileSB.name] = file;
    navigateToFilePage(file, fileSB);
  }

  void navigateToFilePage(Uint8List fileBytes, FileSB fileSB) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePage(fileSB: fileSB, file: fileBytes),
      ),
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
            builder: (context) => ExpireDateChangeModal(fileSB: fileSB),
          ).whenComplete(() {
            setState(() {});
          });
        },
      ),
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
