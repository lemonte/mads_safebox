import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mads_safebox/models/shared.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../global/colors.dart';
import '../services/file_service.dart';
import '../widgets/custom_appbar.dart';
import '../models/file.dart';
import '../widgets/openlinkmodal.dart';
import '../widgets/sharefilemodal.dart';

class FilePage extends StatefulWidget {
  final FileSB fileSB;
  final SharedSB? sharedSB;

  ///tou a passar o fileSB porque pode ser preciso para fazer a partilha (remover se nao for)
  final Uint8List file;
  FilePage({super.key, required this.fileSB, required this.file, this.sharedSB} );

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
            Row(
              children: [
                Container(width: 40,),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Your File",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  child: IconButton(
                    onPressed: (){
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return FileShareModal(fileSB: widget.fileSB);
                        }
                      );
                    },
                    icon: Icon(Icons.share, color: mainColor)
                  ),
                )
              ],
            ),
            Divider(thickness: 1, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            buildFileView(),
          ],
        ),
      ),
    );
  }
}
