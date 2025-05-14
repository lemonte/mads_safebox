import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/global/colors.dart';
import 'package:mads_safebox/riverpod/loggeduserprovider.dart';
import 'package:mads_safebox/views/uploadfiles.dart';
import 'package:mads_safebox/widgets/logoutbutton.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {

  bool isShowingImages = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003366),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.lock, color: Colors.orange, size: 20),
            SizedBox(width: 6),
            Text("SafeBoX", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: LogoutButton(),
          )
        ],
        leading: Padding(
          padding: EdgeInsets.only(left: 12),
          child: PopupMenuButton(
            icon: Icon(Icons.menu, color: mainTextColor,),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.link, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Open Link", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.add_box, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Add File", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UploadFilesPage(),)
                    );
                  },
                ),
                PopupMenuItem(
                  child: Row(
                    children: const [
                      Icon(Icons.notifications_active, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Notifications", style: TextStyle(color: Colors.black)),
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
                          color: isShowingImages ? Colors.grey.shade200 : Colors.white,
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
                          color: isShowingImages ? Colors.white : Colors.grey.shade200,
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
          const Spacer(),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text("View Shared Files", style: TextStyle(color: mainTextColor),),
                ),
                ElevatedButton(
                  onPressed: () {
                    // showDialog(
                    //   context: context,
                    //   builder: (context) => const FilePickerDialog(),
                    // );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UploadFilesPage(),)
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text("Add File", style: TextStyle(color: mainTextColor),),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}


