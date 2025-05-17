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

  Future<bool> deleteFile(FileSB fileSB) async {
    try {
      await supabaseClient.storage.from(authService.getCurrentUser().id).remove([fileSB.path]);
      await supabaseClient.from('files').delete().eq("id", fileSB.id);
      return true;
    } catch (e) {
      print("\nError when deleting file:\n$e\n");
      return false;
    }
  }


  Future<bool> renameFile(FileSB fileSB, String name) async {
    try {

      String newPath = fileSB.path.substring(0, fileSB.path.length - fileSB.name.length) + name;
      await supabaseClient.storage.from(authService.getCurrentUser().id).copy(fileSB.path, newPath);
      await supabaseClient.storage.from(authService.getCurrentUser().id).remove([fileSB.path]);
      await supabaseClient.from('files').update({"name": name, "path": newPath}).eq("id", fileSB.id);
      return true;
    } catch (e) {
      print("\nError when renaming file:\n$e\n");
      return false;
    }
  }

  Future<Uint8List?> getFile(String path) async {

    try {
      final Uint8List response = await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .download(path);

      print("File downloaded: ${response.lengthInBytes} bytes");

      return response;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<FileSB> getFileSB(int id) {
    return supabaseClient
        .from('files')
        .select()
        .eq('id', id)
        .single()
        .then((data) => FileSB.fromJson(data));
  }

  Stream<List<FileSB>?> getImageList() {
    final userId = authService.getCurrentUser().id;

    return supabaseClient
        .from('files')
        .stream(primaryKey: ['id']) // ajuste conforme sua tabela
        .eq("uid", userId)
        .order('created_at', ascending: false)
        .map((data) => data
        .where((file) => ["jpeg", "jpg", "png"]
        .contains(file['extension']?.toLowerCase()))
        .map<FileSB>((file) => FileSB.fromJson(file))
        .toList());
  }

  Stream<List<FileSB>?> getDocList() {
    final userId = authService.getCurrentUser().id;

    return supabaseClient
        .from('files')
        .stream(primaryKey: ['id'])
        .eq("uid", userId)
        .order('created_at', ascending: false)
        .map((data) => data
        .where((file) => ["pdf"]
        .contains(file['extension']?.toLowerCase()))
        .map<FileSB>((file) => FileSB.fromJson(file))
        .toList());
  }
}
