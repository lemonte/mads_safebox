import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class UserData extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  bool isAutoSyncOn;

  @HiveField(2)
  bool allowDownloadWithMobileData;

  //UserData({required this.filesInDevice, required this.favoriteCategory, required this.username});
  UserData({
    this.username = '',
    this.isAutoSyncOn = false,
    this.allowDownloadWithMobileData = false,
  });
}
