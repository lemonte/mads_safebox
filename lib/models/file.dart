class FileSB {
   int id;
   DateTime createdAt;
   String uid;
   String name;
   String extension;
   int size;
   String path;
   int categoryId;

   FileSB({
      required this.id,
      required this.createdAt,
      required this.uid,
      required this.name,
      required this.extension,
      required this.size,
      required this.path,
      required this.categoryId
   });

   Map<String, dynamic> toJson() {
      return {
         'id': id,
         'created_at': createdAt.toIso8601String(),
         'uid': uid,
         'name': name,
         'extension': extension,
         'size': size,
         'path': path,
         'category_id': categoryId,
      };
   }

   factory FileSB.fromJson(Map<String, dynamic> json) {
      return FileSB(
         id: json['id'] as int,
         createdAt: DateTime.parse(json['created_at']),
         uid: json['uid'] as String,
         name: json['name'] as String,
         extension: json['extension'] as String,
         size: json['size'] as int,
         path: json['path'] as String,
         categoryId: json['category_id'] as int,
      );
   }

   @override
   bool operator ==(Object other) =>
       identical(this, other) ||
           other is FileSB && runtimeType == other.runtimeType && id == other.id;

   @override
   int get hashCode => id.hashCode;
}
