import 'package:hive/hive.dart';

import 'hive_user_data.dart';

class UserDataAdapter extends TypeAdapter<UserData> {
  @override
  final int typeId = 0;

  @override
  UserData read(BinaryReader reader) {
    return UserData(
      username: reader.readString(),
      isAutoSyncOn: reader.readBool(),
      allowDownloadWithMobileData: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, UserData obj) {
    writer.writeString(obj.username);
    writer.writeBool(obj.isAutoSyncOn);
    writer.writeBool(obj.allowDownloadWithMobileData);
  }
}
