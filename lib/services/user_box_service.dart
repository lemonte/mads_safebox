import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../global/default_values.dart';
import '../models/hive_user_data.dart';
import '../models/hive_user_data_adapter.dart';

class UserBoxService {
  Future<void> init() async {
    Directory? supportDirectory;
    try {
      supportDirectory = await getApplicationSupportDirectory();
      final targetDirPath =
          "${supportDirectory.path}/userDataBox";
      await Directory(targetDirPath).create(recursive: true);
      Hive.init(targetDirPath);
      Hive.registerAdapter(UserDataAdapter());
    } catch (e) {
      debugPrint("Erro user_box_service: $e");
    }
    await Hive.openBox(usersBoxKey);
  }

  List<String> getUsers() {
    Box usersBox = Hive.box(usersBoxKey);
    return usersBox.keys.cast<String>().toList();
  }

  String getUsername(String uid){
    Box usersBox = Hive.box(usersBoxKey);
    var user = usersBox.get(uid) as UserData? ?? UserData();
    return user.username;
  }

  void addUserData(String uid, String username) {
    Box usersBox = Hive.box(usersBoxKey);
    if (usersBox.containsKey(uid)) {
      return;
    }
    UserData user = UserData();
    user.username = username;
    usersBox.put(uid, user);
  }

  bool getAutoSync(String uid){
    Box usersBox = Hive.box(usersBoxKey);
    var user = usersBox.get(uid) as UserData? ?? UserData();
    return user.isAutoSyncOn;
  }

  void updateAutoSyncPreference(String uid, bool isAutoSyncOn) {
    Box usersBox = Hive.box(usersBoxKey);
    var user = usersBox.get(uid) as UserData? ?? UserData();
    user.isAutoSyncOn = isAutoSyncOn;
    usersBox.put(uid, user);
  }

  bool getAllowDownloadWithMobileData(String uid){
    Box usersBox = Hive.box(usersBoxKey);
    var user = usersBox.get(uid) as UserData? ?? UserData();
    return user.allowDownloadWithMobileData;
  }

  void updateAllowDownloadWithMobileData(String uid, bool allowDownloadWithMobileData) {
    Box usersBox = Hive.box(usersBoxKey);
    var user = usersBox.get(uid) as UserData? ?? UserData();
    user.allowDownloadWithMobileData = allowDownloadWithMobileData;
    usersBox.put(uid, user);
  }
}
