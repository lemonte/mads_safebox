import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mads_safebox/global/default_values.dart';
import 'package:path_provider/path_provider.dart';

class CategoryBoxService {
  static Future<void> init() async {
    Directory? supportDirectory;
    try {
      supportDirectory = await getApplicationSupportDirectory();
      final targetDirPath =
          "${supportDirectory.path}/categoryBox";
      await Directory(targetDirPath).create(recursive: true);
      Hive.init(targetDirPath);
    } catch (e) {
      debugPrint(e.toString());
    }
    await Hive.openBox(categoryBoxKey);
  }

  static int getFavoriteCategory(String uid){
    Box categoryBox = Hive.box(categoryBoxKey);
    debugPrint("fav category de $uid: ${categoryBox.get(uid, defaultValue: 1)}");
    return categoryBox.get(uid, defaultValue: 1);
  }

  static void saveFavoriteCategory(String uid, int categoryId) {
    Box categoryBox = Hive.box(categoryBoxKey);
    categoryBox.put(uid, categoryId);
    debugPrint("fav category de $uid: ${categoryBox.get(uid, defaultValue: 1)}");
  }
}