import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../global/colors.dart';
import '../services/file_service.dart';
import '../widgets/custom_appbar.dart';
import '../models/file.dart';

class FilePage extends StatefulWidget {
  final FileSB fileSB;

  ///tou a passar o fileSB porque pode ser preciso para fazer a partilha (remover se nao for)
  final Uint8List file;
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
    return Expanded(
      child: Center(
        child: SfPdfViewer.memory(widget.file),
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
            const Text("Your File",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Divider(thickness: 1, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            buildFileView(),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {}, //TODO: function to share the file
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                "Share this file",
                style: TextStyle(color: mainTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
