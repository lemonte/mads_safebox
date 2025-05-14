class UserSB {
   String id;
   String nome;

   UserSB({required this.id, required this.nome});

   Map<String, dynamic> toJson() {
      return {
         'id': id,
         'nome': nome,
      };
   }

   factory UserSB.fromJson(Map<String, dynamic> json) {
      return UserSB(
         id: json['id'] as String,
         nome: json['name'] as String,
      );
   }
}