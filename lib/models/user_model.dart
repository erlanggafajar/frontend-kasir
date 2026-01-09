class User {
  final int id;
  final String name;
  final String email;
  final int tokoId;
  final String hakAkses;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.tokoId,
    required this.hakAkses,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      tokoId: json['toko_id'],
      hakAkses: json['hak_akses'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'toko_id': tokoId,
      'hak_akses': hakAkses,
    };
  }
}
