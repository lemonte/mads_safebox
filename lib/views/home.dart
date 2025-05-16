import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/global/colors.dart';
import 'package:mads_safebox/views/filePage.dart';
import 'package:mads_safebox/views/uploadfiles.dart';
import 'package:mads_safebox/widgets/logoutbutton.dart';

import '../models/file.dart';
import '../services/file_service.dart';
import '../widgets/custom_snack_bar.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  FileService fileService = FileService();
  bool isShowingImages = true;

  late Future<List<FileSB>?> images;
  late Future<List<FileSB>?> docs;

  @override
  void initState() {
    super.initState();
    images = fileService.getImageList();
    docs = fileService.getDocList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, color: Colors.orange, size: 20),
            SizedBox(width: 6),
            Text("SafeBoX",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LogoutButton(),
          )
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: PopupMenuButton(
            icon: Icon(
              Icons.menu,
              color: mainTextColor,
            ),
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Open Link", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.add_box, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Add File", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadFilesPage(),
                        ));
                  },
                ),
                const PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Notifications",
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ),
      ),
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

  FutureBuilder<List<FileSB>?> buildFileList() {
    return FutureBuilder<List<FileSB>?>(
      future: isShowingImages
          ? images
          : docs, //TODO : meter os docs (ver se da com o isShowingImage ? images : docs
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
            color: mainColor,
          ));
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading files."));
        } else {
          if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No files found."));
          }
          return ListView(
            children: [
              for (int i = 0; i < snapshot.data!.length; i++)
                Container(
                  //decoration: BoxDecoration(
                  //border: Border.all(color: Globals.borderColor, width: 1),
                  //color: getSeverityColor(snapshot.data![i].severity),
                  //),
                  child: ListTile(
                    onTap: () async {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Center(
                            child: Column(
                              children: [
                                const Text("Downloading File"),
                                const SizedBox(height: 8),
                                CircularProgressIndicator(color: mainColor),
                              ],
                            ),
                          );
                        },
                      );

                      Uint8List? file = await fileService.getFile(snapshot.data![i]);

                      print(snapshot.data![i].path);

                      if (context.mounted) {
                        Navigator.pop(context);

                        if (file == null) {
                          showCustomSnackBar(
                              context, 'Could not download the file');
                          return;
                        }


                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FilePage(
                                  fileSB: snapshot.data![i], file: file),
                            ));
                      }
                    },
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child:
                              Icon(Icons.image), //TODO : Colocar aqui a imagem
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            snapshot.data![i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Icon(Icons.menu),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
      },
    );
  }
}
