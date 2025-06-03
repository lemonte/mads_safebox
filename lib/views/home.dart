import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:mads_safebox/services/category_box_service.dart';
import 'package:mads_safebox/services/category_service.dart';
import 'package:mads_safebox/views/filepage.dart';
import 'package:mads_safebox/views/sharedfilespage.dart';
import 'package:mads_safebox/views/uploadfiles.dart';
import 'package:mads_safebox/widgets/category/category_create_modal.dart';
import 'package:mads_safebox/widgets/category/category_delete_modal.dart';
import 'package:mads_safebox/widgets/loading.dart';
import 'package:mads_safebox/widgets/custom_appbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/category.dart';
import '../models/file.dart';
import '../services/auth_service.dart';
import '../services/file_service.dart';
import '../services/user_box_service.dart';
import '../widgets/category/category_dropdownbutton.dart';
import '../widgets/category/category_rename_modal.dart';
import '../widgets/custom_snack_bar.dart';
import '../widgets/sharefilemodal.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  AuthService authService = AuthService();
  FileService fileService = FileService();
  CategoryService categoryService = CategoryService();

  bool isShowingImages = true;
  TextEditingController renameController = TextEditingController();

  Map<String, Uint8List> downloadedFiles = {};

  late Stream<List<FileSB>?> images;
  late Stream<List<FileSB>?> docs;
  late Future<List<CategorySB>> categories;

  CategorySB selectedCategory = defaultCategory;
  int favoriteCategoryId = 1;
  bool autoSyncEnabled = false, allowDownloadWithMobileData = false;

  @override
  void initState() {
    super.initState();

    initValues();
    initAsyncValues();

    categories.then((value) {
      setState(() {
        favoriteCategoryId = CategoryBoxService.getFavoriteCategory(
            authService.getCurrentUser().id);
        selectedCategory = value.firstWhere(
          (element) => element.id == favoriteCategoryId,
          orElse: () => defaultCategory,
        );
      });
    });
  }

  @override
  void dispose() {
    renameController.dispose();
    super.dispose();
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> downloadFile(
      BuildContext context, FileSB fileSB, bool notifications) async {
    try {
      final directory = await getDownloadsDirectory();
      final userId = authService.getCurrentUser().id;

      final targetDirPath =
          "${directory!.path}/$userId/${fileSB.path.split("/").first}";
      final fileFullPath = "$targetDirPath/${fileSB.path.split("/").last}";
      final file = File(fileFullPath);

      await Directory(targetDirPath).create(recursive: true);

      if (await file.exists()) {
        if (!context.mounted) return;
        handleFileAlreadyExists(context, fileSB.name, notifications);
        return;
      }

      // await requestStoragePermission();

      if (!downloadedFiles.containsKey(fileSB.name)) {
        Uint8List? fileData = await fileService.getFile(fileSB.path);
        if (fileData == null) throw Exception("Failed to fetch file data");
        downloadedFiles[fileSB.name] = fileData;
      }

      await file.writeAsBytes(downloadedFiles[fileSB.name]!);

      if (notifications) {
        await showDownloadNotification(fileSB.name, file.path);
      }
      if (!context.mounted) return;
      handleDownloadSuccess(context, notifications);
    } catch (e) {
      if (!context.mounted) return;
      handleDownloadError(context, notifications, e);
    }
  }

  void handleFileAlreadyExists(
      BuildContext context, String name, bool notifications) {
    if (notifications) {
      showCustomSnackBar(context, "O arquivo '$name' já existe.");
    }
  }

  void handleDownloadSuccess(BuildContext context, bool notifications) {
    if (notifications) {
      showCustomSnackBar(context, "File downloaded");
    }
  }

  void handleDownloadError(BuildContext context, bool notifications, Object e) {
    if (notifications) {
      showCustomSnackBar(context, "Error downloading file $e");
    }
  }

  void navigateToFilePage(Uint8List fileBytes, FileSB fileSB) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePage(fileSB: fileSB, file: fileBytes),
      ),
    );
  }

  Future<void> showDownloadNotification(String fileName, String path) async {
    final granted = await Permission.notification.request().isGranted;
    if (!granted) return;

    await flutterLocalNotificationsPlugin.show(
      0,
      'Download concluído',
      fileName,
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
      payload: path,
    );
  }

  Future<void> initAsyncValues() async {
    categories = categoryService.getCategories();
    images = fileService.getImageList();
    docs = fileService.getDocList();
  }

  void initValues() {
    ///Add user to hive box
    UserBoxService.addUserData(
        authService.getCurrentUser().id, authService.getCurrentUser().nome);

    autoSyncEnabled =
        UserBoxService.getAutoSync(authService.getCurrentUser().id);

    allowDownloadWithMobileData = UserBoxService.getAllowDownloadWithMobileData(
        authService.getCurrentUser().id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(
        false,
        autoSyncEnabled: autoSyncEnabled,
        allowDownloadWithMobileData: allowDownloadWithMobileData,
        onToggleAutoSync: () async {
          UserBoxService.updateAutoSyncPreference(
              authService.getCurrentUser().id, !autoSyncEnabled);

          setState(() {
            autoSyncEnabled = !autoSyncEnabled;
          });
        },
        onToggleDownloadWithMobileData: () async {
          UserBoxService.updateAllowDownloadWithMobileData(
              authService.getCurrentUser().id, !allowDownloadWithMobileData);

          setState(() {
            allowDownloadWithMobileData = !allowDownloadWithMobileData;
          });
        },
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 12),
          //Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                buildCategoryDropdown(
                  categoriesFuture: categories,
                  selectedCategory: selectedCategory,
                  onChanged: (CategorySB? value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                ...buildCategoryActionButtons(context),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tabs (Files / Images)
          buildFileTypeSelector(),
          const SizedBox(height: 24),
          Text(
            isShowingImages ? "Your Images" : "Your Files",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // File List
          Expanded(
            child: buildFileList(),
          ),
          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    List<CategorySB> catValue = await categories;
                    if (!context.mounted) return;
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CategoryCreateModal(categories: catValue);
                      },
                    ).then((value) async {
                      if (value != null) {
                        (await categories).add(value);
                        setState(() {});
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "Add Category",
                    style: TextStyle(color: mainTextColor),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // showDialog(
                    //   context: context,
                    //   builder: (context) => const FilePickerDialog(),
                    // );
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadFilesPage(),
                        )).then((value) {
                      setState(() {
                        initAsyncValues();
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    "Add File",
                    style: TextStyle(color: mainTextColor),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SharedFilesPage(),
                    ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                "View Shared Files",
                style: TextStyle(color: mainTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildCategoryActionButtons(BuildContext context) {
    List<Widget> buttonList = [];

    if (selectedCategory.id != favoriteCategoryId) {
      buttonList.add(InkWell(
        onTap: () {
          ///guardar a categoria fav
          CategoryBoxService.saveFavoriteCategory(
              authService.getCurrentUser().id, selectedCategory.id);
          favoriteCategoryId = selectedCategory.id;
          setState(() {});
        },
        child: const Icon(
          Icons.star_border_sharp,
          color: mainColor,
        ),
      ));
    } else {
      buttonList.add(InkWell(
        onTap: () {
          CategoryBoxService.saveFavoriteCategory(
              authService.getCurrentUser().id, 1);
          favoriteCategoryId = 1;
          setState(() {});
        },
        child: const Icon(
          Icons.star_border_sharp,
          color: Colors.amberAccent,
        ),
      ));
    }
    buttonList.add(const SizedBox(width: 8));

    if (selectedCategory.id != 1) {
      buttonList.add(InkWell(
        onTap: () async {
          List<CategorySB> catValues = await categories;
          if (!context.mounted) return;
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return CategoryRenameModal(
                  categories: catValues,
                  selectedCategoryId: selectedCategory.id,
                );
              }).then((value) async {
            if (value != null) {
              selectedCategory.name = value;
              (await categories)
                  .firstWhere((element) => element.id == selectedCategory.id)
                  .name = value;
              setState(() {});
            }
          });
        },
        child: const Icon(
          Icons.edit,
          color: mainColor,
        ),
      ));
      buttonList.add(const SizedBox(width: 8));
      buttonList.add(InkWell(
        onTap: () async {
          List<CategorySB> catValues = (await categories).toList();

          ///remove the selected category so the user cant transfer the files to the category being deleted
          catValues.remove(selectedCategory);
          if (!context.mounted) return;
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return CategoryDeleteModal(
                    categories: Future.value(catValues),
                    idCategoryToDelete: selectedCategory.id);
              }).then((value) async {
            if (value != null) {
              (await categories).remove(selectedCategory);
              selectedCategory = (await categories).first;
              CategoryBoxService.saveFavoriteCategory(
                  authService.getCurrentUser().id, 1);
              favoriteCategoryId = 1;
              setState(() {});
            }
          });
        },
        child: const Icon(
          Icons.delete,
          color: mainColor,
        ),
      ));
    } else {
      buttonList.add(Icon(
        Icons.edit,
        color: Colors.grey.shade300,
      ));
      buttonList.add(const SizedBox(width: 8));
      buttonList.add(Icon(
        Icons.delete,
        color: Colors.grey.shade300,
      ));
    }

    return buttonList;
  }

  Padding buildFileTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            // Files tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => isShowingImages = false);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isShowingImages ? Colors.grey.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.insert_drive_file,
                    color: isShowingImages ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            // Images tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => isShowingImages = true);
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        isShowingImages ? Colors.white : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.image,
                    color: isShowingImages ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StreamBuilder<List<FileSB>?> buildFileList() {
    return StreamBuilder<List<FileSB>?>(
      stream: isShowingImages ? images : docs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loading());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading files."));
        } else {
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No files found."));
          }

          List<ListTile> tiles = buildFilesListTiles(snapshot.data!);

          return tiles.isEmpty
              ? const Center(child: Text("No files found."))
              : ListView(children: tiles);
        }
      },
    );
  }

  void handleFileOpen(FileSB fileSB, Uint8List? fileBytes) {
    Navigator.pop(context);

    if (fileBytes == null) {
      showCustomSnackBar(context, 'Could not download the file');
      return;
    }

    downloadedFiles[fileSB.name] = fileBytes;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FilePage(fileSB: fileSB, file: fileBytes),
      ),
    );
  }

  List<ListTile> buildFilesListTiles(List<FileSB> files) {
    List<ListTile> tiles = [];

    for (int i = 0; i < files.length; i++) {
      if (selectedCategory.id != files[i].categoryId) {
        continue;
      }

      tiles.add(ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 4,
              child: GestureDetector(
                onTap: () async {
                  if (downloadedFiles.containsKey(files[i].name)) {
                    navigateToFilePage(
                        downloadedFiles[files[i].name]!, files[i]);
                    return;
                  }

                  try {
                    Directory? directory;
                    directory = await getDownloadsDirectory();
                    final userId = authService.getCurrentUser().id;
                    final targetDirPath =
                        "${directory!.path}/$userId/${files[i].path.split("/").first}";
                    final fileFullPath =
                        "$targetDirPath/${files[i].path.split("/").last}";
                    final filePath = fileFullPath;
                    final downloadedFile = File(filePath);
                    if (await downloadedFile.exists()) {
                      final fileBytes = await downloadedFile.readAsBytes();
                      if (!mounted) return;
                      navigateToFilePage(fileBytes, files[i]);
                      return;
                    }
                  } on Exception catch (e) {
                    debugPrint("\nError checking downloaded file: $e\n");
                  }

                  if (!mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

                  Uint8List? file = await fileService.getFile(files[i].path);

                  debugPrint(files[i].path);

                  if (!mounted) return;
                  handleFileOpen(files[i], file);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      flex: 1,
                      child: Icon(Icons
                          .image), //TODO : Colocar aqui a miniatura da imagem
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        files[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: PopupMenuButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.black,
                ),
                itemBuilder: (BuildContext context) {
                  return getFileOptionsButtonList(files[i]);
                },
              ),
            )
          ],
        ),
      ));
    }

    return tiles;
  }

  List<PopupMenuItem> getFileOptionsButtonList(FileSB fileSB) {
    return [
      PopupMenuItem(
        child: const Text("Delete", style: TextStyle(color: Colors.black)),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                            "Are you sure you want to delete this file?"),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final bool response =
                                    await fileService.deleteFile(fileSB);
                                if (response) {
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop();
                                  showCustomSnackBar(context, "File deleted");
                                  setState(() {
                                    images = fileService.getImageList();
                                    docs = fileService.getDocList();
                                  });
                                  return;
                                }
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                showCustomSnackBar(context,
                                    "An error occurred when deleting the file");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(80, 36),
                              ),
                              child: const Text('Delete'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(80, 36),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              });
        },
      ),
      PopupMenuItem(
        child: const Text("Rename", style: TextStyle(color: Colors.black)),
        onTap: () {
          renameController.text = fileSB.name
              .substring(0, fileSB.name.length - fileSB.extension.length - 1);

          showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Write the new name"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: renameController,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final bool response = await fileService.renameFile(
                                    fileSB,
                                    "${renameController.text.trim()}.${fileSB.extension}");
                                if (!context.mounted) return;
                                if (response) {
                                  Navigator.of(context).pop();
                                  showCustomSnackBar(context, "File renamed");
                                  setState(() {
                                    images = fileService.getImageList();
                                    docs = fileService.getDocList();
                                  });
                                  return;
                                }
                                Navigator.of(context).pop();
                                showCustomSnackBar(context,
                                    "An error occurred when renaming the file");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(80, 36),
                              ),
                              child: const Text('Rename'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                minimumSize: const Size(80, 36),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              });
        },
      ),
      PopupMenuItem(
        child: const Text("Share", style: TextStyle(color: Colors.black)),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return FileShareModal(fileSB: fileSB);
              });
        },
      ),
      PopupMenuItem(
        child: const Text("Download", style: TextStyle(color: Colors.black)),
        onTap: () async {
          await downloadFile(context, fileSB, true);
        },
      ),
    ];
  }
}
