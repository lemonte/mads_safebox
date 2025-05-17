class SharedSB {
  final int id;
  final int fileId;
  final String uid;
  final DateTime expireDate;
  final String role;
  final String url;
  final String password;
  final String path;
  final List<String> sharedWith;

  SharedSB({
    required this.id,
    required this.fileId,
    required this.uid,
    required this.expireDate,
    required this.role,
    required this.url,
    required this.password,
    required this.path,
    required this.sharedWith,
  });

  factory SharedSB.fromJson(Map<String, dynamic> json) {
    return SharedSB(
      id: json['id'],
      fileId: json['file_id'],
      uid: json['uid'],
      expireDate: DateTime.parse(json['expire_date']),
      role: json['role'],
      url: json['url'],
      password: json['password'],
      path: json['path'],
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_id': fileId,
      'uid': uid,
      'expire_date': expireDate.toIso8601String(),
      'role': role,
      'url': url,
      'password': password,
      'path': path,
      'sharedWith': sharedWith,
    };
  }

  @override
  String toString() {
    return 'SharedSB{id: $id, fileId: $fileId, uid: $uid, expireDate: $expireDate, role: $role, url: $url, password: $password, path: $path, sharedWith: $sharedWith}';
  }
}
