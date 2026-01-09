import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();

  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasReachedMax = false;
  List<ProductModel> products = [];
  List<ProductModel> filtered = [];

  String _query = '';
  int _stockFilter = 1; // 0 = all, 1 = available only, 2 = out of stock only
  String _sortBy = 'nama'; // Default sort by name
  bool _isAscending = true;

  // Store current tokoId for data isolation
  int _currentTokoId = 0;

  // Update tokoId for data filtering
  void updateTokoId(int tokoId) {
    _currentTokoId = tokoId;
    _service.updateTokoId(tokoId);
    debugPrint('ProductProvider: Toko ID updated to $_currentTokoId');
  }

  // Pagination properties
  int _currentPage = 1;
  final int _pageSize = 5;
  String _lastSearchQuery = '';

  // Getter untuk mengakses status filter (opsional, berguna untuk UI)
  String get query => _query;
  bool get onlyAvailable => _stockFilter == 1;
  bool get onlyOutOfStock => _stockFilter == 2;
  int get stockFilter => _stockFilter;
  String get sortBy => _sortBy;
  bool get isAscending => _isAscending;

  // ======================
  // AMBIL PRODUK DENGAN PAGINATION
  // ======================
  Future<void> fetchProducts(String token, {bool refresh = false}) async {
    debugPrint('PROVIDER: Memuat daftar produk... (refresh: $refresh)');

    if (refresh) {
      _currentPage = 1;
      products.clear();
      hasReachedMax = false;
      _lastSearchQuery = _query;
    }

    isLoading = refresh;
    notifyListeners();

    try {
      final newProducts = await _service.getProducts(
        token: token,
        page: _currentPage,
        limit: _pageSize,
        search: _lastSearchQuery,
      );

      if (refresh) {
        products = newProducts;
      } else {
        products.addAll(newProducts);
      }

      // Check if we've reached the end
      if (newProducts.length < _pageSize) {
        hasReachedMax = true;
        debugPrint('PROVIDER: Reached end of products');
      }

      _applyFilter();
    } catch (e) {
      if (refresh) {
        products = [];
        filtered = [];
      }
      debugPrint('PROVIDER ERROR [fetchProducts]: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // LOAD MORE PRODUCTS (INFINITE SCROLL)
  // ======================
  Future<void> loadMoreProducts(String token) async {
    if (isLoadingMore || hasReachedMax) return;

    debugPrint('PROVIDER: Loading more products...');
    isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;

      final newProducts = await _service.getProducts(
        token: token,
        page: _currentPage,
        limit: _pageSize,
        search: _lastSearchQuery,
      );

      products.addAll(newProducts);

      // Check if we've reached the end
      if (newProducts.length < _pageSize) {
        hasReachedMax = true;
        debugPrint('PROVIDER: Reached end of products');
      }

      _applyFilter();
    } catch (e) {
      // Revert page number on error
      _currentPage--;
      debugPrint('PROVIDER ERROR [loadMoreProducts]: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  // Legacy method for backward compatibility
  Future<void> fetchAllProducts(String token) async {
    await fetchProducts(token, refresh: true);
  }

  // ======================
  // LOGIKA PENCARIAN & FILTER
  // ======================
  void search(String query) {
    _query = query.toLowerCase();

    // If search query changed significantly, trigger a refresh
    if (_lastSearchQuery != _query) {
      _currentPage = 1;
      hasReachedMax = false;
      _lastSearchQuery = _query;

      // Clear products and let fetchProducts handle the search
      products.clear();
      filtered.clear();
      notifyListeners();
    } else {
      _applyFilter();
    }
  }

  void toggleAvailable(bool value) {
    _stockFilter = value
        ? 1
        : 2; // true = available only, false = out of stock only
    _applyFilter();
  }

  void setSort(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _isAscending = ascending;
    } else {
      // Toggle ascending if same sort field, otherwise default to ascending
      _isAscending = (_sortBy == sortBy) ? !_isAscending : true;
    }
    _applyFilter();
  }

  // Method to trigger search with API call
  Future<void> performSearch(String token, String query) async {
    _query = query.toLowerCase();
    if (_lastSearchQuery != _query) {
      _lastSearchQuery = _query;
      await fetchProducts(token, refresh: true);
    }
  }

  void _applyFilter() {
    filtered = products.where((p) {
      final matchQuery =
          p.nama.toLowerCase().contains(_query) ||
          p.kodeBarang.toLowerCase().contains(_query);

      final bool matchStock;
      switch (_stockFilter) {
        case 0: // Show all
          matchStock = true;
          break;
        case 1: // Available only
          matchStock = p.stok > 0;
          break;
        case 2: // Out of stock only
          matchStock = p.stok <= 0;
          break;
        default:
          matchStock = true;
      }

      return matchQuery && matchStock;
    }).toList();

    // Apply sorting
    _sortProducts();

    // Use WidgetsBinding to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _sortProducts() {
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'nama':
          comparison = a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
          break;
        case 'kode':
          comparison = a.kodeBarang.toLowerCase().compareTo(
            b.kodeBarang.toLowerCase(),
          );
          break;
        case 'harga':
          comparison = a.harga.compareTo(b.harga);
          break;
        case 'stok':
          comparison = a.stok.compareTo(b.stok);
          break;
        default:
          comparison = a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
      }
      return _isAscending ? comparison : -comparison;
    });
  }

  // ======================
  // TAMBAH PRODUK (CREATE)
  // ======================
  Future<void> createProduct({
    required String kodeBarang,
    required String nama,
    required int harga,
    required int stok,
    required String token,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _service.createProduct(
        kodeBarang: kodeBarang,
        nama: nama,
        harga: harga,
        stok: stok,
        token: token,
      );

      // Setelah berhasil tambah ke server, ambil data terbaru agar UI sinkron
      await fetchProducts(token, refresh: true);
    } catch (e) {
      debugPrint('PROVIDER ERROR [createProduct]: $e');
      rethrow; // Lempar error agar bisa ditangkap SnackBar di UI
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // EDIT PRODUK (UPDATE)
  // ======================
  Future<void> updateProduct({
    required int id,
    required String kodeBarang,
    required String nama,
    required int harga,
    required int stok,
    required String token,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _service.updateProduct(
        id: id,
        kodeBarang: kodeBarang,
        nama: nama,
        harga: harga,
        stok: stok,
        token: token,
      );

      // Refresh daftar agar perubahan muncul di list utama
      await fetchProducts(token, refresh: true);
    } catch (e) {
      debugPrint('PROVIDER ERROR [updateProduct]: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // HAPUS PRODUK (DELETE)
  // ======================
  Future<void> deleteProduct(int id, String token) async {
    isLoading = true;
    notifyListeners();

    try {
      await _service.deleteProduct(id, token);

      // Hapus secara lokal untuk performa lebih cepat atau fetch ulang
      products.removeWhere((p) => p.id == id);
      _applyFilter();
    } catch (e) {
      debugPrint('PROVIDER ERROR [deleteProduct]: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ======================
  // SCANNER & DETAIL
  // ======================
  Future<ProductModel?> findByKodeBarang({
    required String kodeBarang,
    required String token,
  }) async {
    try {
      return await _service.getProductByKode(
        kodeBarang: kodeBarang,
        token: token,
      );
    } catch (e) {
      debugPrint('PROVIDER ERROR [findByKodeBarang]: $e');
      rethrow;
    }
  }

  Future<ProductModel> getProductDetail(int id, String token) async {
    try {
      return await _service.getProductDetail(id, token);
    } catch (e) {
      debugPrint('PROVIDER ERROR [getProductDetail]: $e');
      rethrow;
    }
  }
}
