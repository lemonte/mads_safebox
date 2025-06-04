import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/models/sharedplusfile.dart';
import 'package:mads_safebox/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/file.dart';

class FileService {
  // This class is responsible for file operations
  // such as reading, writing, and deleting files.
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final AuthService authService = AuthService();

  Future<void> uploadFile(List<File> file, int? selectedCategoryId,
      DateTime? expiringDate, DateTime? notificationDate) async {
    if (expiringDate != null && expiringDate.isBefore(DateTime.now())) {
      debugPrint('Error: Expiration date must be in the future.');
      throw Exception('Expiration date must be in the future');
    }
    try {
      await supabaseClient.storage
          .createBucket(authService.getCurrentUser().id);
    } catch (e) {
      // Handle the case where the bucket already exists
      if (e.toString().contains('The resource already exists')) {
        debugPrint('Bucket already exists, proceeding with upload.');
      } else {
        debugPrint('Error creating bucket: $e');
      }
    }
    for (var file in file) {
      try {
        String uploadPath =
            '${DateTime.now().millisecondsSinceEpoch}/${file.path.split('/').last}';
        debugPrint("Upload path: $uploadPath");

        final response = await supabaseClient.storage
            .from(authService.getCurrentUser().id)
            .upload(uploadPath, file);

        debugPrint("File uploaded: $response");

        var expireDateToSupabase =
            DateFormat('yyyy-MM-dd').format(expiringDate ?? DateTime.now());
        var notificationDateToSupabase =
            DateFormat('yyyy-MM-dd').format(notificationDate ?? DateTime.now());
        await supabaseClient.from('files').insert({
          'uid': authService.getCurrentUser().id,
          'name': file.path.split('/').last,
          'extension': file.path.split('.').last,
          'size': file.lengthSync(),
          'path': uploadPath,
          'category_id': selectedCategoryId,
          'expire_date':
              expiringDate == null ? expiringDate : expireDateToSupabase,
          'notification_date': notificationDate == null
              ? notificationDate
              : notificationDateToSupabase,
        });
      } catch (e) {
        debugPrint('Error uploading file: $e');
      }
    }
  }

  Future<bool> deleteFile(FileSB fileSB) async {
    try {
      await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .remove([fileSB.path]);
      await supabaseClient.from('files').delete().eq("id", fileSB.id);

      //delete local file if exists
      final directory = await getDownloadsDirectory();
      final userId = authService.getCurrentUser().id;
      final targetDirPath =
          "${directory!.path}/$userId/${fileSB.path.split("/").first}";
      final fileFullPath = "$targetDirPath/${fileSB.path.split("/").last}";
      final file = File(fileFullPath);

      if (await file.exists()) {
        await file.delete();
        Directory dir = Directory(targetDirPath);
        if (await dir.list().isEmpty) {
          await dir.delete();
        }
      }

      return true;
    } catch (e) {
      debugPrint("\nError when deleting file:\n$e\n");
      return false;
    }
  }

  Future<bool> renameFile(FileSB fileSB, String name) async {
    try {
      String newPath =
          fileSB.path.substring(0, fileSB.path.length - fileSB.name.length) +
              name;
      await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .copy(fileSB.path, newPath);
      await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .remove([fileSB.path]);
      await supabaseClient
          .from('files')
          .update({"name": name, "path": newPath}).eq("id", fileSB.id);
      await supabaseClient
          .from('shared')
          .update({"path": newPath}).eq("file_id", fileSB.id);
      return true;
    } catch (e) {
      debugPrint("\nError when renaming file:\n$e\n");
      return false;
    }
  }

  Future<Uint8List?> getFile(String path) async {
    try {
      final Uint8List response = await supabaseClient.storage
          .from(authService.getCurrentUser().id)
          .download(
              path); //todo removi o transform porque dava erro com os pdfs

      debugPrint("$path downloaded: ${response.lengthInBytes} bytes");

      return response;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<Uint8List?> getSharedFile(String path, String uid) async {
    try {
      final Uint8List response =
          await supabaseClient.storage.from(uid).download(path);

      debugPrint("File downloaded: ${response.lengthInBytes} bytes");

      return response;
    } catch (e) {
      debugPrint(e.toString());
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
        .stream(primaryKey: ['id'])
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
            .where((file) => ["pdf"].contains(file['extension']?.toLowerCase()))
            .map<FileSB>((file) => FileSB.fromJson(file))
            .toList());
  }

  Future<bool> changeFilesCategory(int idOrigin, int idDestination) async {
    try {
      await supabaseClient
          .from('files')
          .update({'category_id': idDestination})
          .eq('uid', authService.getCurrentUser().id)
          .eq('category_id', idOrigin);

      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<List<SharedFileSB>> getSharedFiles(
      List<SharedFileSB> sharedFiles) async {
    try {
      for (var sharedFile in sharedFiles) {
        final response = await supabaseClient
            .from('files')
            .select()
            .eq('id', sharedFile.sharedSB.fileId)
            .single();

        sharedFile.fileSB = FileSB.fromJson(response);
      }

      return sharedFiles;
    } catch (e) {
      debugPrint('Error fetching shared files: $e');

      return [];
    }
  }

  Future<List<FileSB>> getAllFilesList(String uid) async {
    List<FileSB> fileList = [];
    try {
      final response =
          await supabaseClient.from('files').select().eq('uid', uid);

      fileList.addAll(response.map((item) => FileSB.fromJson(item)).toList());
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
    return fileList;
  }

  Future<List<FileSB>> getExpiringFiles() async {
    try {
      final response = await supabaseClient
          .from('files')
          .select()
          .eq('uid', authService.getCurrentUser().id)
          .not('expire_date', 'is', null)
          .order('expire_date', ascending: true)
          .then((data) => (data as List)
              .map((item) => FileSB.fromJson(item as Map<String, dynamic>))
              .toList());
      debugPrint("Expiring files fetched: ${response.length} files");
      return response;
    } catch (e) {
      debugPrint('Error fetching shared files: $e');

      return [];
    }
  }

  Future<void> changeFileExpireDate(
      int fileId, DateTime? newExpireDate, DateTime? notificationDate) async {
    try {
      var expireDateToSupabase =
          DateFormat('yyyy-MM-dd').format(newExpireDate ?? DateTime.now());
      var notificationDateToSupabase =
          DateFormat('yyyy-MM-dd').format(notificationDate ?? DateTime.now());

      await supabaseClient.from('files').update({
        'expire_date':
            newExpireDate == null ? newExpireDate : expireDateToSupabase,
        'notification_date': notificationDate == null
            ? notificationDate
            : notificationDateToSupabase,
      }).eq('id', fileId);
    } catch (e) {
      debugPrint('Error changing file expiration date: $e');
    }
  }
}
