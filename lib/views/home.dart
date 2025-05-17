import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/global/colors.dart';
import 'package:mads_safebox/views/filePage.dart';
import 'package:mads_safebox/views/uploadfiles.dart';
import 'package:mads_safebox/widgets/loading.dart';
import 'package:mads_safebox/widgets/logoutbutton.dart';
import 'package:mads_safebox/widgets/custom_appbar.dart';
import 'package:mads_safebox/widgets/loading.dart';

import '../models/file.dart';
import '../services/file_service.dart';
import '../widgets/custom_snack_bar.dart';
import '../widgets/openlinkmodal.dart';
import '../widgets/sharefilemodal.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  FileService fileService = FileService();
  bool isShowingImages = true;

  Map<String, Uint8List> downloadedFiles = {};

  late Stream<List<FileSB>?> images;
  late Stream<List<FileSB>?> docs;

  @override
  void initState() {
    super.initState();
    images = fileService.getImageList();
    docs = fileService.getDocList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(false),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Tabs (Files / Images)
          Padding(
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
                          color: isShowingImages
                              ? Colors.grey.shade200
                              : Colors.white,
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
                          color: isShowingImages
                              ? Colors.white
                              : Colors.grey.shade200,
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
          ),
          const SizedBox(height: 24),
          Text(
            isShowingImages ? "Your Images" : "Your Files",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            //height: 500,
            child: buildFileList(),
          ),
          //const Spacer(),
          // Bottom buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "View Shared Files",
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
                        ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "Add File",
                    style: TextStyle(color: mainTextColor),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  StreamBuilder<List<FileSB>?> buildFileList() {
    return StreamBuilder<List<FileSB>?>(
      stream: isShowingImages ? images : docs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Loading());
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

                            Uint8List? file = await fileService
                                .getFile(snapshot.data![i].path);

                            print(snapshot.data![i].path);

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
                              Expanded(
                                flex: 1,
                                child: Icon(Icons
                                    .image), //TODO : Colocar aqui a miniatura da imagem
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  snapshot.data![i].name,
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
                            return getButtonList(snapshot.data![i]);
                          },
                        ),
                      )
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
                                  Navigator.of(context).pop();
                                  showCustomSnackBar(context, "File deleted");
                                  setState(() {
                                    images = fileService.getImageList();
                                    docs = fileService.getDocList();
                                  });
                                  return;
                                }

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
          TextEditingController renameController = TextEditingController(
              text: fileSB.name.substring(
                  0, fileSB.name.length - fileSB.extension.length - 1));

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
              }).whenComplete(() {
            renameController.dispose();
          });
        },
      ),
      PopupMenuItem(
        ///Share File
        child: const Text("Share", style: TextStyle(color: Colors.black)),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return FileShareModal(fileSB: fileSB);
              });
        },
      ),
    ];
  }
}
