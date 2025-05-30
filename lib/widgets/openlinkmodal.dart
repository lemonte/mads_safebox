import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:mads_safebox/models/file.dart';
import 'package:mads_safebox/models/shared.dart';
import 'package:mads_safebox/services/file_service.dart';
import 'package:mads_safebox/services/sharefiles_service.dart';
import 'package:mads_safebox/views/filepage.dart';
import 'package:mads_safebox/widgets/custom_snack_bar.dart';
import 'package:mads_safebox/widgets/loading.dart';

import '../config/env_config.dart';
import '../global/colors.dart';
import '../models/role.dart';

class OpenLinkModal extends StatefulWidget {
  const OpenLinkModal({super.key});

  @override
  State<OpenLinkModal> createState() => _OpenLinkModalState();
}

class _OpenLinkModalState extends State<OpenLinkModal> {

  final TextEditingController linkController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String finalUrl = '';

  ShareFilesService shareFilesService = ShareFilesService();
  FileService fileService = FileService();

  bool loading = false;


  String decryptUrl(String encryptedBase64) {
    debugPrint('Decrypting URL: $encryptedBase64');

    final combinedKey = utf8.encode((EnvConfig().publicKey + EnvConfig().privateKey).padRight(32, '0')).sublist(0, 32);
    final key = encrypt.Key(combinedKey);

    final ivString = EnvConfig().ivKey;
    final iv = encrypt.IV.fromUtf8(ivString);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encryptedBytes = base64Url.decode(encryptedBase64);

    final decrypted = encrypter.decrypt(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );

    return decrypted;
  }

  void openLink(String url, String password) async {
    try {
      setState(() {
        loading = true;
      });

      final uriParts = url.trim().split('/');
      final encryptedPart = uriParts.removeLast();
      final decrypted = decryptUrl(encryptedPart);

      final baseUrl = uriParts.join('/');
      final finalResolvedUrl = '$baseUrl/$decrypted';

      finalUrl = finalResolvedUrl;
      debugPrint(decrypted);


      int fileId = int.parse(decrypted.split('/').first);
      DateTime expireDate = DateTime.fromMillisecondsSinceEpoch(int.parse(decrypted.split('/').elementAt(1)));
      String roleString = decrypted.split('/').last;

      Role role = Role.values.firstWhere(
            (e) => e.name == roleString,
        orElse: () => Role.view,
      );


      debugPrint(fileId.toString());
      debugPrint(expireDate.toString());
      debugPrint(role.name);


      SharedSB? response = await shareFilesService.getSharedFileFromLink(fileId, expireDate, role, password);
      if(response == null){
        if(mounted){
          showCustomSnackBar(context, 'File not found or incorrect password');
          setState(() {
            loading = false;
          });
        }
        return;
      }

      FileSB fileSB = await fileService.getFileSB(response.fileId);

      Uint8List? file = await fileService.getSharedFile(response.path, response.uid);

      if(file == null){
        if(mounted){
          showCustomSnackBar(context, 'File not found');
          setState(() {
            loading = false;
          });
        }
        return;
      }
      if(mounted) {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilePage(fileSB: fileSB, file: file, sharedSB: response),
            )
        );
        setState(() {
          loading = false;
        });
      }
    } on Exception catch (e) {
      if(e.toString().contains('Autorization expired')){
        debugPrint('Error decrypting link: $e');
        if(!mounted) return;
        showCustomSnackBar(context, 'Autorization expired');
      } else {
        debugPrint('Error decrypting link: $e');
        if(!mounted) return;
        showCustomSnackBar(context, 'Error decrypting link');
      }
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: 'Share Link',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password (if needed)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    !loading ? ElevatedButton(
                      onPressed: () {
                        final link = linkController.text.trim();
                        final password = passwordController.text.trim();
                        openLink(link, password);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Open', style: TextStyle(color: mainTextColor)),
                    ) : const Center(
                      child: Loading(),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Close', style: TextStyle(color: mainTextColor)),
                    ),
                  ],
                ),
              ]
          ),
        )
    );
  }
}
