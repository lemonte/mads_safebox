import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mads_safebox/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/file.dart';

class FileService {
  // This class is responsible for file operations
  // such as reading, writing, and deleting files.
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final AuthService authService = AuthService();

  Future<void> uploadFile(
      List<File> file, String? selectedCategory, DateTime? expiringDate) async {
    try {
      await supabaseClient.storage
          .createBucket(authService.getCurrentUser().id);
    } catch (e) {
      // Handle the case where the bucket already exists
      if (e.toString().contains('The resource already exists')) {
        print('Bucket already exists, proceeding with upload.');
      } else {
        print('Error creating bucket: $e');
      }
    }
    for (var file in file) {
      try {
        String uploadPath = DateTime.now().millisecondsSinceEpoch.toString() +
            '/' +
            file.path.split('/').last;
        print("Upload path: $uploadPath");
        final response = await supabaseClient.storage
            .from(authService.getCurrentUser().id)
            .upload(uploadPath, file);
        print("File uploaded: ${response}");

        await supabaseClient.from('files').insert({
          'uid': authService.getCurrentUser().id,
          'name': file.path.split('/').last,
          'extension': file.path.split('.').last,
          'size': file.lengthSync(),
          'path': uploadPath,
        });
      } catch (e) {
        print('Error uploading file: $e');
      }
    }
  }

  Future<Uint8List?> getFile(FileSB fileSB) async {

    try {
      final Uint8List response = await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .download(fileSB.path);

      print("File downloaded: ${response.lengthInBytes} bytes");

      return response;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<List<FileSB>?> getImageList() async {
    List<FileSB> images = [];
    try {
      final List<Map<String, dynamic>> data = await supabaseClient.from('files').select().eq("uid", authService.getCurrentUser().id).likeAnyOf("extension", ["jpeg","jpg","png"]);

      for(var file in data) {
        images.add(FileSB.fromJson(file));
      }

      print("imagens:\n$data");
    } catch (e) {
      print(e.toString());
    }

    return images;

  }

  Future<List<FileSB>?> getDocList() async {
    List<FileSB> docs = [];
    try {
      final List<Map<String, dynamic>> data = await supabaseClient.from('files').select().eq("uid", authService.getCurrentUser().id).eq("extension", "pdf");

      for(var file in data) {
        docs.add(FileSB.fromJson(file));
      }

      print("documentos:\n$data");
    } catch (e) {
      print(e.toString());
    }
    return docs;
  }
}
