import 'dart:convert';
import 'package:mads_safebox/models/role.dart';
import 'package:share_plus/share_plus.dart';
import 'package:encrypt/encrypt.dart'  as encrypt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/models/file.dart';
import 'package:mads_safebox/services/sharefiles_service.dart';

import '../global/default_values.dart';
import '../config/env_config.dart';
import 'custom_snack_bar.dart';

class FileShareModal extends StatefulWidget {
  final FileSB fileSB;
  const FileShareModal({super.key, required this.fileSB});

  @override
  State<FileShareModal> createState() => _FileShareModalState();
}

class _FileShareModalState extends State<FileShareModal> {

  DateTime expiringDate = DateTime.now().add(const Duration(days: 1));
  bool noExpiration = false;
  TextEditingController passwordController = TextEditingController();
  String url = '';

  Role selectedCategory = Role.view;

  String encryptUrl(String url) {

    final combinedKey = utf8.encode((EnvConfig().publicKey + EnvConfig().privateKey).padRight(32, '0')).sublist(0, 32);
    final key = encrypt.Key(combinedKey);

    final ivString = EnvConfig().ivKey;
    final iv = encrypt.IV.fromUtf8(ivString);


    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(url, iv: iv);


    return base64Url.encode(encrypted.bytes);
  }

  void shareFile() async {
    setState(() {
      url = 'https://safebox.com/${encryptUrl('${widget.fileSB.id}/${expiringDate.millisecondsSinceEpoch}/${selectedCategory.name}')}';
    });
    ShareFilesService shareFilesService = ShareFilesService();
    try{
      await shareFilesService.shareFile(widget.fileSB.id, widget.fileSB.path, expiringDate, selectedCategory, url, passwordController.text.trim());
    } catch (e) {
      debugPrint('Error sharing file: $e');

      if (!mounted) return;
      showCustomSnackBar(context, e.toString());

      return;
    }
    String text = 'I\'m sharing this file with you: $url';
    if(passwordController.text.trim().isNotEmpty) {
      text += '\nPassword: ${passwordController.text}';
    }
    //Clipboard.setData(ClipboardData(text: url));
    await SharePlus.instance.share(
        ShareParams(text: text, title: 'Share File', subject: 'File Sharing')
    );

    // showCustomSnackBar(context, 'Link copied to clipboard');
    return;
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "File Name",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Expiring Date + Role
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (noExpiration) return;
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: expiringDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          expiringDate = pickedDate;
                          url = '';
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            noExpiration
                                ? 'dd/mm/yyyy'
                                : DateFormat('dd/MM/yyyy').format(expiringDate),
                            style: const TextStyle(color: Colors.black),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Role>(
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        value: selectedCategory,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: Role.values.map((Role role) {
                          final String capitalized = role.name[0].toUpperCase() + role.name.substring(1);
                          return DropdownMenuItem<Role>(
                            value: role,
                            child: Text(capitalized),
                          );
                        }).toList(),
                        onChanged: (Role? newValue) {
                          setState(() {
                            selectedCategory = newValue!;
                            debugPrint('Selected Role: ${selectedCategory.name}');
                            url = '';
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // No Expiration checkbox
            Row(
              children: [
                const Text('No Expiration:'),
                Checkbox(
                  value: noExpiration,
                  onChanged: (bool? value) {
                    setState(() {
                      noExpiration = value!;
                      if (noExpiration) {
                        expiringDate = DateTime(2200);
                      } else {
                        expiringDate = DateTime.now().add(const Duration(days: 1));
                      }
                      url = '';
                    });
                  },
                ),
              ],
            ),

            // Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            // URL + Share button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                    },
                    child: Text(
                      url,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 14,
                        color: mainColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: shareFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'Share',
                    style: TextStyle(color: mainTextColor, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
