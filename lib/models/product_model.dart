class ProductModel {
  final int id;
  final String kodeBarang;
  final String nama;
  final int harga;
  final int stok;

  ProductModel({
    required this.id,
    required this.kodeBarang,
    required this.nama,
    required this.harga,
    required this.stok,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      kodeBarang: json['kode_barang'] ?? '',
      nama: json['nama'] ?? '',
      harga: json['harga'] ?? 0,
      stok: json['stok'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_barang': kodeBarang,
      'nama': nama,
      'harga': harga,
      'stok': stok,
    };
  }

  ProductModel copyWith({
    int? id,
    String? kodeBarang,
    String? nama,
    int? harga,
    int? stok,
  }) {
    return ProductModel(
      id: id ?? this.id,
      kodeBarang: kodeBarang ?? this.kodeBarang,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
    );
  }
}
