class KasirModel {
  final int id;
  final String name;
  final String email;
  final String hakAkses;
  final int tokoId;

  KasirModel({
    required this.id,
    required this.name,
    required this.email,
    required this.hakAkses,
    required this.tokoId,
  });

  factory KasirModel.fromJson(Map<String, dynamic> json) {
    return KasirModel(
      id: json['id'] as int,
      name: json['nama'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      hakAkses: json['hak_akses'] ?? '',
      tokoId: json['toko_id'] ?? 0,
    );
  }
}
