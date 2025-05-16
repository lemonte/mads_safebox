import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../global/colors.dart';
import '../services/file_service.dart';
import '../widgets/logoutbutton.dart';
import '../models/file.dart';

class FilePage extends StatefulWidget {
  late FileSB fileSB;

  ///tou a passar o fileSB porque pode ser preciso para fazer a partilha (remover se nao for)
  late Uint8List file;
  FilePage({super.key, required this.fileSB, required this.file});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  FileService fileService = FileService();

  Widget buildFileView() {
    if (widget.fileSB.extension != "pdf") {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.memory(
                widget.file,
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 8),
              Text(widget.fileSB.name),
            ],
          ),
        ),
      );
    }
    //TODO: meter o pdf viewer
    return const Expanded(
      child: Center(
        child: Text("PDF File"),
      ),
    );
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
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Back", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Open Link", style: TextStyle(color: Colors.black)),
                    ],
                  ),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            const Text("Your File",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Divider(thickness: 1, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            buildFileView(),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {}, //TODO: function to share the file being shown
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text("Share this file"),
            ),
          ],
        ),
      ),
    );
  }
}
