import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:mads_safebox/models/role.dart';
import 'package:mads_safebox/models/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sharedplusfile.dart';

class ShareFilesService {

  Future<void> shareFile(int fileId, String filePath, DateTime expireDate, Role role, String url, String password) async {
    if(expireDate.isBefore(DateTime.now())) {
      debugPrint('Error: Expiration date must be in the future.');
      throw Exception('Expiration date must be in the future');
    }
    if(role != Role.view && role != Role.download) {
      debugPrint('Error: Role must be either "View" or "Download".');
      throw Exception('Role must be either "View" or "Download".');
    }
    var expireDateToSupabase = DateFormat(dateFormatToSupabase).format(expireDate);
    debugPrint(role.name);
    try {
      await Supabase.instance.client
          .from('shared')
          .insert({
            'file_id': fileId,
            'path': filePath,
            'uid': Supabase.instance.client.auth.currentUser!.id,
            'expire_date': expireDateToSupabase,
            'role': role.name,
            'url': url,
            'password': password,
          });
    } catch (e) {
      debugPrint('Error sharing file: $e');
      throw Exception('Error sharing file $e');
    }
  }

  Future<SharedSB?> getSharedFileFromLink(int fileId, DateTime date, Role role, String password) async {
    if(date.isBefore(DateTime.now())) {
      debugPrint('Error: Autorization expired.');
      throw Exception('Autorization expired');
    }

    try {
      final response = await Supabase.instance.client
          .from('shared')
          .select()
          .eq('file_id', fileId)
          .eq('expire_date', date)
          .eq('role', role.name)
          .eq('password', password);
      debugPrint('Response: $response');
      final List<SharedSB> sharedList = (response)
          .map((item) => SharedSB.fromJson(item))
          .toList();
      if(sharedList.isEmpty){
        return null;
      }
      SharedSB sharedSB = sharedList.first;

      if(!sharedSB.sharedWith.contains(Supabase.instance.client.auth.currentUser!.id)){
        sharedSB.sharedWith.add(Supabase.instance.client.auth.currentUser!.id);

        await Supabase.instance.client
            .from('shared')
            .update({'sharedWith': sharedSB.sharedWith})
            .eq('id', sharedSB.id);
      }
      return sharedSB;


    } catch (e) {
      debugPrint('Error fetching shared files: $e');
      return null;
    }
  }

  Future<List<SharedFileSB>> getSharedFiles() async {

    try {
      final response = await Supabase.instance.client
          .from('shared')
          .select()
          .contains('sharedWith', [Supabase.instance.client.auth.currentUser!.id])
          .gte('expire_date', DateFormat(dateFormatToSupabase).format(DateTime.now()));
      final List<SharedSB> sharedList = (response)
          .map((item) => SharedSB.fromJson(item))
          .toList();

      List<SharedFileSB> sharedFiles = sharedList.map(
        (shared) {
          return SharedFileSB(
            sharedSB: shared,
          );
        },
      ).toList();

      return sharedFiles;
    } catch (e) {
      debugPrint('Error fetching shared files: $e');
      throw Exception('Error fetching shared files');
    }
  }

}