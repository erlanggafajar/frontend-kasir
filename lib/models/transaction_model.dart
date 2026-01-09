import 'package:flutter/foundation.dart';

class TransactionItem {
  final int id;
  final int idBarang;
  int qty;
  final String namaBarang;
  final int harga;
  int subtotal;

  TransactionItem({
    required this.id,
    required this.idBarang,
    required this.qty,
    required this.namaBarang,
    required this.harga,
    required this.subtotal,
  });

  // For cart usage (temporary)
  TransactionItem.cart({
    required int productId,
    required int quantity,
    required String productName,
    required double price,
  }) : id = 0,
       idBarang = productId,
       qty = quantity,
       namaBarang = productName,
       harga = price.toInt(),
       subtotal = (price * quantity).toInt();

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final raw = v.toString().trim();
    if (raw.isEmpty) return 0;

    var s = raw.replaceAll(RegExp(r'[^0-9,\.\-]'), '');
    if (s.isEmpty || s == '-') return 0;

    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '');
      s = s.replaceAll(',', '.');
    } else if (s.contains(',') && !s.contains('.')) {
      final parts = s.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        s = '${parts[0]}.${parts[1]}';
      } else {
        s = parts.join('');
      }
    } else if (s.contains('.')) {
      final parts = s.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        // keep as decimal
      } else {
        s = parts.join('');
      }
    }

    final d = double.tryParse(s);
    return d?.round() ?? 0;
  }

  static String _toStr(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final dynamic barang = json['barang'] ?? json['produk'] ?? json['product'];
    final Map<String, dynamic>? barangMap = barang is Map
        ? Map<String, dynamic>.from(barang)
        : null;

    final dynamic pivot = json['pivot'];
    final Map<String, dynamic>? pivotMap = pivot is Map
        ? Map<String, dynamic>.from(pivot)
        : null;

    final int qty = _toInt(
      json['qty'] ??
          json['quantity'] ??
          json['jumlah'] ??
          json['jml'] ??
          pivotMap?['qty'],
    );

    final int harga = _toInt(
      json['harga'] ??
          json['price'] ??
          json['harga_satuan'] ??
          barangMap?['harga'],
    );

    final int subtotal = _toInt(
      json['subtotal'] ??
          json['total'] ??
          json['jumlah_harga'] ??
          (harga * qty),
    );

    return TransactionItem(
      id: _toInt(json['id'] ?? json['detail_id']),
      idBarang: _toInt(
        json['id_barang'] ??
            json['barang_id'] ??
            json['produk_id'] ??
            json['product_id'] ??
            barangMap?['id'],
      ),
      qty: qty,
      namaBarang: _toStr(
        json['nama_barang'] ??
            json['nama'] ??
            json['nama_produk'] ??
            barangMap?['nama'] ??
            barangMap?['nama_barang'],
      ),
      harga: harga,
      subtotal: subtotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_barang': idBarang, 'qty': qty};
  }

  // For cart operations
  TransactionItem copyWith({
    int? id,
    int? idBarang,
    int? qty,
    String? namaBarang,
    int? harga,
    int? subtotal,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      idBarang: idBarang ?? this.idBarang,
      qty: qty ?? this.qty,
      namaBarang: namaBarang ?? this.namaBarang,
      harga: harga ?? this.harga,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  // Getters for compatibility with existing code
  int get productId => idBarang;
  int get quantity => qty;
  String get productName => namaBarang;
  String get namaProduk => namaBarang; // Added for compatibility
  double get price => harga.toDouble();
  double get priceAsDouble => harga.toDouble();
  double get subtotalAsDouble => subtotal.toDouble();

  // Setter for quantity (updates subtotal automatically)
  set quantity(int value) {
    qty = value;
    subtotal = harga * qty;
  }
}

class Transaction {
  final int id;
  final String tanggal;
  final String namaKasir;
  final String? userRole;
  final int? userId; // Tambahkan user_id
  final int? tokoId; // Tambahkan toko_id untuk filtering
  final List<TransactionItem> items;
  final int totalHarga;

  Transaction({
    required this.id,
    required this.tanggal,
    required this.namaKasir,
    this.userRole,
    this.userId,
    this.tokoId,
    required this.items,
    required this.totalHarga,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    final raw = v.toString().trim();
    if (raw.isEmpty) return 0;

    var s = raw.replaceAll(RegExp(r'[^0-9,\.\-]'), '');
    if (s.isEmpty || s == '-') return 0;

    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '');
      s = s.replaceAll(',', '.');
    } else if (s.contains(',') && !s.contains('.')) {
      final parts = s.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        s = '${parts[0]}.${parts[1]}';
      } else {
        s = parts.join('');
      }
    } else if (s.contains('.')) {
      final parts = s.split('.');
      if (parts.length == 2 && parts[1].length <= 2) {
        // keep as decimal
      } else {
        s = parts.join('');
      }
    }

    final d = double.tryParse(s);
    return d?.round() ?? 0;
  }

  static String _toStr(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  static List<TransactionItem> _parseItems(dynamic raw) {
    if (raw is List) {
      return raw.map((e) {
        if (e is Map<String, dynamic>) {
          return TransactionItem.fromJson(e);
        } else if (e is Map) {
          return TransactionItem.fromJson(Map<String, dynamic>.from(e));
        } else {
          throw Exception('Invalid transaction item format: $e');
        }
      }).toList();
    }
    if (raw is Map) {
      final inner = raw['data'] ?? raw['items'] ?? raw['detail'] ?? raw['list'];
      if (inner is List) {
        return inner.map((e) {
          if (e is Map<String, dynamic>) {
            return TransactionItem.fromJson(e);
          } else if (e is Map) {
            return TransactionItem.fromJson(Map<String, dynamic>.from(e));
          } else {
            throw Exception('Invalid transaction item format: $e');
          }
        }).toList();
      }
    }
    return [];
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    debugPrint('Transaction.fromJson input: ${json.toString()}');

    final dynamic kasir = json['kasir'] ?? json['user'] ?? json['pegawai'];
    final Map<String, dynamic>? kasirMap = kasir is Map
        ? Map<String, dynamic>.from(kasir)
        : null;

    debugPrint('Kasir data: $kasir, KasirMap: $kasirMap');

    final items = _parseItems(
      json['items'] ??
          json['detail'] ??
          json['details'] ??
          json['detail_transaksi'] ??
          json['detailTransaksi'] ??
          json['transaksi_detail'] ??
          json['rincian'],
    );

    final totalFromItems = items.fold<int>(0, (sum, it) => sum + it.subtotal);
    final totalHarga = _toInt(
      json['total_harga'] ??
          json['totalHarga'] ??
          json['total'] ??
          json['grand_total'] ??
          json['total_bayar'] ??
          json['jumlah_harga'] ??
          (totalFromItems > 0 ? totalFromItems : null),
    );

    final tanggalRaw =
        json['tanggal'] ?? json['created_at'] ?? json['updated_at'];
    final tanggal = tanggalRaw is Map
        ? _toStr(tanggalRaw['date'] ?? tanggalRaw['iso'] ?? '')
        : _toStr(tanggalRaw);

    final namaKasirValue = _toStr(
      json['nama_kasir'] ??
          json['namaKasir'] ??
          kasirMap?['name'] ??
          kasirMap?['nama'] ??
          kasirMap?['username'],
    );

    debugPrint('Parsed namaKasir: "$namaKasirValue"');

    return Transaction(
      id: _toInt(json['id'] ?? json['transaksi_id']),
      tanggal: tanggal,
      namaKasir: namaKasirValue,
      userRole: _toStr(json['user_role'] ?? json['userRole']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      tokoId: _toInt(json['toko_id'] ?? json['tokoId']),
      items: items,
      totalHarga: totalHarga,
    );
  }

  // Factory method with fallback for missing kasir name
  factory Transaction.fromJsonWithFallback(
    Map<String, dynamic> json, {
    String? fallbackKasirName,
  }) {
    debugPrint('=== DEBUG: fromJsonWithFallback called ===');
    debugPrint('fallbackKasirName: "$fallbackKasirName"');

    final transaction = Transaction.fromJson(json);
    debugPrint('Original namaKasir: "${transaction.namaKasir}"');
    debugPrint('Is namaKasir empty: "${transaction.namaKasir.trim().isEmpty}"');

    // If namaKasir is empty and fallback is provided, use fallback
    if (transaction.namaKasir.trim().isEmpty && fallbackKasirName != null) {
      debugPrint('Using fallback kasir name: "$fallbackKasirName"');
      return Transaction(
        id: transaction.id,
        tanggal: transaction.tanggal,
        namaKasir: fallbackKasirName,
        userRole: transaction.userRole,
        userId: transaction.userId,
        tokoId: transaction.tokoId,
        items: transaction.items,
        totalHarga: transaction.totalHarga,
      );
    }

    debugPrint('No fallback applied, returning original transaction');
    return transaction;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal,
      'nama_kasir': namaKasir,
      'user_role': userRole,
      'user_id': userId,
      'toko_id': tokoId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_harga': totalHarga,
    };
  }
}

class TransactionResponse {
  final List<Transaction> data;
  final String? message;

  TransactionResponse({required this.data, this.message});

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'];
    List<Transaction> transactions = [];

    if (dataList is List) {
      transactions = dataList.map((e) {
        if (e is Map<String, dynamic>) {
          return Transaction.fromJson(e);
        } else if (e is Map) {
          return Transaction.fromJson(Map<String, dynamic>.from(e));
        } else {
          throw Exception('Invalid transaction format: $e');
        }
      }).toList();
    }

    return TransactionResponse(data: transactions, message: json['message']);
  }
}
