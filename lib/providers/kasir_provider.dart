import 'package:flutter/material.dart';

import '../models/kasir_model.dart';
import '../services/kasir_service.dart';

class KasirProvider extends ChangeNotifier {
  final KasirService _service = KasirService();

  bool isLoading = false;
  String? errorMessage;
  List<KasirModel> kasirList = [];
  List<KasirModel> filteredKasirList = [];

  // ======================
  // FETCH LIST KASIR
  // ======================
  Future<void> fetchKasir({required String token}) async {
    if (token.isEmpty) {
      errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      kasirList = await _service.getKasir(token: token);
      filteredKasirList = List.from(
        kasirList,
      ); // Initialize filtered list with all items
    } catch (e) {
      kasirList = [];
      filteredKasirList = [];

      if (e.toString().contains('401') ||
          e.toString().contains('Unauthenticated')) {
        errorMessage = 'Sesi login habis, silakan login ulang';
      } else {
        errorMessage = e.toString();
      }

      debugPrint('ERROR FETCH KASIR: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // SEARCH KASIR BY NAME
  // ======================
  void searchKasir(String query) {
    if (query.isEmpty) {
      filteredKasirList = List.from(kasirList);
    } else {
      final searchQuery = query.toLowerCase();
      filteredKasirList = kasirList
          .where(
            (kasir) =>
                kasir.name.toLowerCase().contains(searchQuery) ||
                kasir.email.toLowerCase().contains(searchQuery),
          )
          .toList();
    }
    notifyListeners();
  }

  // ======================
  // CREATE KASIR
  // ======================
  Future<bool> addKasir({
    required String name,
    required String email,
    required String password,
    required String token,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.createKasir(
        name: name,
        email: email,
        password: password,
        token: token,
      );

      // refresh list
      await fetchKasir(token: token);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('ERROR ADD KASIR: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // UPDATE KASIR
  // ======================
  Future<bool> updateKasir({
    required int id,
    required String name,
    required String email,
    String? password,
    required String token,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.updateKasir(
        id: id,
        name: name,
        email: email,
        password: password,
        token: token,
      );

      await fetchKasir(token: token);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('ERROR UPDATE KASIR: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // DELETE KASIR
  // ======================
  Future<bool> deleteKasir({required int id, required String token}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteKasir(id: id, token: token);

      kasirList.removeWhere((e) => e.id == id);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('ERROR DELETE KASIR: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // CLEAR STATE (LOGOUT)
  // ======================
  void clear() {
    kasirList = [];
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }
}
