class CategorySB {
  int id;
  DateTime createdAt;
  String? uid;
  String name;

  CategorySB({
    required this.id,
    required this.createdAt,
    required this.uid,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'uid': uid,
      'name': name,
    };
  }

  factory CategorySB.fromJson(Map<String, dynamic> json) {
    return CategorySB(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at']),
      uid: json['uid'] as String?,
      name: json['name'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CategorySB && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
