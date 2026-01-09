import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/navigation/route_names.dart';
import '../../styles/color_style.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../services/user_service.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _sortBy = 'tanggal'; // Default sort by date
  final bool _isAscending = true;
  int _currentPage = 1;
  final int _itemsPerPage = 5;
  Set<int> _selectedTransactions = {};

  // Date filtering variables
  String _dateFilter = 'semua'; // semua, hari, minggu, bulan
  DateTime? _startDate;
  DateTime? _endDate;

  // Cache for user names to avoid repeated API calls
  final Map<int, String> _userNameCache = {};

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Date filtering methods
  void _showDateFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Filter Laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('Semua'),
            trailing: _dateFilter == 'semua' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _dateFilter = 'semua';
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.today),
            title: const Text('Hari Ini'),
            trailing: _dateFilter == 'hari' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _dateFilter = 'hari';
                _startDate = DateTime.now();
                _endDate = DateTime.now();
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Minggu Ini'),
            trailing: _dateFilter == 'minggu' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _dateFilter = 'minggu';
                final now = DateTime.now();
                _startDate = now.subtract(Duration(days: now.weekday - 1));
                _endDate = _startDate!.add(const Duration(days: 6));
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_month),
            title: const Text('Bulan Ini'),
            trailing: _dateFilter == 'bulan' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _dateFilter = 'bulan';
                final now = DateTime.now();
                _startDate = DateTime(now.year, now.month, 1);
                _endDate = DateTime(now.year, now.month + 1, 0);
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Tahun Ini'),
            trailing: _dateFilter == 'tahun' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _dateFilter = 'tahun';
                final now = DateTime.now();
                _startDate = DateTime(now.year, 1, 1);
                _endDate = DateTime(now.year, 12, 31);
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Kustom Tanggal'),
            trailing: _dateFilter == 'kustom' ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.pop(context);
              _showCustomDateRangePicker();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _showCustomDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter = 'kustom';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  String _getDateFilterLabel() {
    switch (_dateFilter) {
      case 'semua':
        return 'Semua';
      case 'hari':
        return 'Hari Ini';
      case 'minggu':
        return 'Minggu Ini';
      case 'bulan':
        return 'Bulan Ini';
      case 'tahun':
        return 'Tahun Ini';
      case 'kustom':
        if (_startDate != null && _endDate != null) {
          return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
        }
        return 'Kustom';
      default:
        return 'Semua';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      // Convert to UTC+7 (WIB) if the date is in UTC
      final wibDate = date.isUtc ? date.toLocal() : date;
      return DateFormat('dd MMMM yyyy, HH:mm').format(wibDate);
    } catch (e) {
      return dateString;
    }
  }

  Future<String> _getUserNameById(
    int userId, {
    Transaction? transaction,
  }) async {
    // Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      final userName = await UserService.getUserNameById(userId, token: token);

      if (userName != null) {
        // Cache the result
        _userNameCache[userId] = userName;
        return userName;
      }
    } catch (e) {
      print('Error fetching user name for user ID $userId: $e');
    }

    // Return fallback to existing namaKasir if available
    if (transaction != null && transaction.namaKasir.trim().isNotEmpty) {
      return transaction.namaKasir;
    }

    return 'Tidak diketahui';
  }

  List<Transaction> _getFilteredTransactions() {
    final provider = context.read<TransactionProvider>();
    final authProvider = context.read<AuthProvider>();
    var transactions = List<Transaction>.from(provider.transactions);

    debugPrint('=== RIWAYAT SCREEN FILTERING ===');
    debugPrint('User role: ${authProvider.userRole}');
    debugPrint('User ID: ${authProvider.userId}');
    debugPrint('Total transactions from provider: ${transactions.length}');

    // TransactionProvider already handles role-based filtering properly
    // No need for additional filtering here

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final beforeSearch = transactions.length;
      transactions = transactions.where((transaction) {
        return transaction.id.toString().contains(_searchQuery) ||
            transaction.namaKasir.toLowerCase().contains(_searchQuery);
      }).toList();
      debugPrint(
        '🔍 Search filter: $beforeSearch -> ${transactions.length} transactions',
      );
    }

    // Apply date filter
    if (_dateFilter != 'semua' && _startDate != null && _endDate != null) {
      final beforeDate = transactions.length;
      transactions = transactions.where((transaction) {
        try {
          final transactionDate = DateTime.parse(transaction.tanggal);
          final transactionDateOnly = DateTime(
            transactionDate.year,
            transactionDate.month,
            transactionDate.day,
          );
          final startDateOnly = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );
          final endDateOnly = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          );
          return transactionDateOnly.isAfter(
                startDateOnly.subtract(const Duration(days: 1)),
              ) &&
              transactionDateOnly.isBefore(
                endDateOnly.add(const Duration(days: 1)),
              );
        } catch (e) {
          debugPrint(
            'Error parsing date for transaction ${transaction.id}: $e',
          );
          return false;
        }
      }).toList();
      debugPrint(
        '📅 Date filter: $beforeDate -> ${transactions.length} transactions',
      );
    }

    debugPrint('📊 Final filtered transactions: ${transactions.length}');
    debugPrint('=== END RIWAYAT SCREEN FILTERING ===');

    return transactions;
  }

  List<Transaction> _sortTransactions(List<Transaction> transactions) {
    final sortedTransactions = List<Transaction>.from(transactions);

    sortedTransactions.sort((a, b) {
      DateTime dateA = DateTime.parse(a.tanggal);
      DateTime dateB = DateTime.parse(b.tanggal);

      int comparison;
      switch (_sortBy) {
        case 'hari':
          comparison = dateA.day.compareTo(dateB.day);
          break;
        case 'tanggal':
          comparison = dateA.compareTo(dateB);
          break;
        case 'bulan':
          comparison = dateA.month.compareTo(dateB.month);
          if (comparison == 0) {
            comparison = dateA.year.compareTo(dateB.year);
          }
          break;
        case 'tahun':
          comparison = dateA.year.compareTo(dateB.year);
          if (comparison == 0) {
            comparison = dateA.month.compareTo(dateB.month);
          }
          if (comparison == 0) {
            comparison = dateA.day.compareTo(dateB.day);
          }
          break;
        default:
          comparison = dateA.compareTo(dateB);
      }

      return _isAscending ? comparison : -comparison;
    });

    return sortedTransactions;
  }

  List<Transaction> _getPaginatedTransactions(List<Transaction> transactions) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= transactions.length) {
      return [];
    }

    return transactions.sublist(
      startIndex,
      endIndex > transactions.length ? transactions.length : endIndex,
    );
  }

  int _getTotalPages(int itemCount) {
    return (itemCount / _itemsPerPage).ceil();
  }

  // Export methods
  Future<void> _exportToPDF() async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.token == null) {
        _showErrorDialog('Token tidak tersedia. Silakan login kembali.');
        return;
      }

      String dateParam = '';
      String formatParam = '';
      if (_dateFilter != 'semua' && _startDate != null) {
        dateParam = '?tanggal=${DateFormat('yyyy-MM-dd').format(_startDate!)}';
        formatParam = '&format=display_number'; // Request custom format
      }

      final url =
          'https://kasir.tgh.my.id/api/transaksi/download-pdf$dateParam$formatParam';
      _showExportOptionsDialog('PDF', url);
    } catch (e) {
      _showErrorDialog('Gagal export PDF: $e');
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.token == null) {
        _showErrorDialog('Token tidak tersedia. Silakan login kembali.');
        return;
      }

      String dateParam = '';
      String formatParam = '';
      if (_dateFilter != 'semua' && _startDate != null) {
        dateParam = '?tanggal=${DateFormat('yyyy-MM-dd').format(_startDate!)}';
        formatParam = '&format=display_number'; // Request custom format
      }

      final url =
          'https://kasir.tgh.my.id/api/transaksi/export$dateParam$formatParam';
      _showExportOptionsDialog('Excel', url);
    } catch (e) {
      _showErrorDialog('Gagal export Excel: $e');
    }
  }

  void _showExportOptionsDialog(String format, String url) {
    final filterInfoText = _dateFilter != 'semua'
        ? '\n\nFilter: ${_getDateFilterLabel()}'
        : '\n\nSemua data akan di-export';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export $format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              filterInfoText,
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text('File $format akan di-download langsung ke perangkat Anda:'),
            const SizedBox(height: 8),
            const Text(
              'File akan tersimpan di folder Download perangkat Anda.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadToDevice(format, url);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadToDevice(String format, String url) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Mendownload file...'),
          ],
        ),
      ),
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Accept': format == 'PDF'
              ? 'application/pdf'
              : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
      );

      if (response.statusCode == 200) {
        // Get system Downloads directory
        Directory? downloadsDir;
        if (Platform.isAndroid) {
          // For Android, use external storage Downloads directory
          downloadsDir = Directory('/storage/emulated/0/Download');
        } else if (Platform.isIOS) {
          // For iOS, get the documents directory and create Downloads folder
          final documentsDir = await getApplicationDocumentsDirectory();
          downloadsDir = Directory('${documentsDir.path}/Downloads');
        } else {
          // For other platforms, try to get Downloads directory
          downloadsDir = await getDownloadsDirectory();
        }

        // Ensure directory exists
        if (downloadsDir != null && !await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        if (downloadsDir != null) {
          final fileName =
              'laporan_transaksi_${_dateFilter}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.${format == 'Excel' ? 'xlsx' : 'pdf'}';
          final filePath = '${downloadsDir.path}/$fileName';

          // Save file
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Close loading dialog
          if (mounted) Navigator.pop(context);

          // Show success dialog
          _showDownloadSuccessDialog(format, fileName, filePath);

          // Try to open the file directly
          if (format == 'PDF') {
            await _openPdfFile(filePath);
          } else if (format == 'Excel') {
            await _openExcelFile(filePath);
          }
        } else {
          throw Exception('Tidak dapat mengakses folder Downloads sistem');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      _showErrorDialog('Gagal download $format: $e');
    }
  }

  void _showDownloadSuccessDialog(
    String format,
    String fileName,
    String filePath,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export $format Berhasil!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File $format telah berhasil di-download:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama File: $fileName',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lokasi: $filePath',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (format == 'PDF')
              const Text(
                'PDF akan langsung dibuka dengan aplikasi PDF yang tersedia di perangkat Anda.',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              )
            else if (format == 'Excel')
              const Text(
                'Excel akan langsung dibuka dengan aplikasi spreadsheet yang tersedia di perangkat Anda.',
                style: TextStyle(fontSize: 12, color: Colors.green),
              )
            else
              const Text(
                'File tersimpan di folder Download perangkat Anda.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'File berhasil di-download! Cek folder Downloads.',
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdfFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        // If opening failed, show a message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tidak dapat membuka PDF. Silakan buka manual dari folder Downloads.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      // If there's an error, show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka PDF: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openExcelFile(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        // If opening failed, show a message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tidak dapat membuka Excel. Silakan buka manual dari folder Downloads.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      // If there's an error, show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka Excel: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Export Laporan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export ke PDF'),
            subtitle: Text(
              _dateFilter != 'semua'
                  ? 'Export laporan ${_getDateFilterLabel()}'
                  : 'Export semua laporan',
            ),
            onTap: () {
              Navigator.pop(context);
              _exportToPDF();
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart, color: Colors.green),
            title: const Text('Export ke Excel'),
            subtitle: Text(
              _dateFilter != 'semua'
                  ? 'Export laporan ${_getDateFilterLabel()}'
                  : 'Export semua laporan',
            ),
            onTap: () {
              Navigator.pop(context);
              _exportToExcel();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<TransactionProvider>().loadTransactions(context: context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTransactionCard(
    Transaction transaction,
    int index,
    List<Transaction> allFilteredTransactions,
  ) {
    // Find the actual position in filtered transactions to get correct display number
    final actualIndex = allFilteredTransactions.indexOf(transaction);
    final displayNumber = actualIndex + 1;
    final isSelected = _selectedTransactions.contains(transaction.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedTransactions.add(transaction.id);
                  } else {
                    _selectedTransactions.remove(transaction.id);
                  }
                });
              },
            ),

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaksi #$displayNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<String>(
                    future: _getUserNameById(
                      transaction.userId ?? 0,
                      transaction: transaction,
                    ),
                    builder: (context, snapshot) {
                      String displayName = 'Tidak diketahui';

                      if (snapshot.hasData) {
                        displayName = snapshot.data!;
                      } else if (snapshot.hasError) {
                        // Fallback to existing namaKasir when API fails
                        if (transaction.namaKasir.trim().isNotEmpty) {
                          displayName = transaction.namaKasir;
                        } else {
                          displayName = 'Error loading';
                        }
                      } else if (transaction.namaKasir.trim().isNotEmpty) {
                        // Show existing namaKasir while loading
                        displayName = transaction.namaKasir;
                      }

                      return Text(
                        'Kasir: $displayName',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateString(transaction.tanggal),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Price and items info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(transaction.totalHarga),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.items.length} item',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),

            // More options button
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showActionSheet(context, transaction),
              tooltip: 'Opsi lainnya',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous',
          ),

          // Page numbers
          ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
            int pageNumber;
            if (totalPages <= 5) {
              pageNumber = index + 1;
            } else if (_currentPage <= 3) {
              pageNumber = index + 1;
            } else if (_currentPage >= totalPages - 2) {
              pageNumber = (totalPages - 4) + index;
            } else {
              pageNumber = (_currentPage - 2) + index;
            }

            // Ensure pageNumber is within valid range
            if (pageNumber < 1) pageNumber = 1;
            if (pageNumber > totalPages) pageNumber = totalPages;

            final isCurrentPage = pageNumber == _currentPage;
            final showDots =
                (index == 0 && pageNumber > 1) ||
                (index == 4 && pageNumber < totalPages);

            if (showDots) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(fontSize: 16)),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentPage = pageNumber;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentPage
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrentPage ? AppColors.primary : Colors.grey,
                    ),
                  ),
                  child: Text(
                    '$pageNumber',
                    style: TextStyle(
                      color: isCurrentPage ? Colors.white : Colors.black,
                      fontWeight: isCurrentPage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Next button
          IconButton(
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }

  void _showActionSheet(BuildContext context, Transaction transaction) {
    final authProvider = context.read<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetItem(
              icon: Icons.info_outline,
              title: 'Detail Transaksi',
              onTap: () {
                Navigator.pop(context);
                // Get filtered transactions from provider to calculate correct display number
                final provider = context.read<TransactionProvider>();
                var filteredTransactions = provider.transactions.where((
                  transaction,
                ) {
                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final matchesSearch =
                        transaction.id.toString().contains(_searchQuery) ||
                        transaction.namaKasir.toLowerCase().contains(
                          _searchQuery,
                        );
                    if (!matchesSearch) return false;
                  }

                  // Apply date filter
                  if (_dateFilter != 'semua') {
                    try {
                      final transactionDate = DateTime.parse(
                        transaction.tanggal,
                      );
                      final transactionDateOnly = DateTime(
                        transactionDate.year,
                        transactionDate.month,
                        transactionDate.day,
                      );

                      if (_startDate != null && _endDate != null) {
                        final startDateOnly = DateTime(
                          _startDate!.year,
                          _startDate!.month,
                          _startDate!.day,
                        );
                        final endDateOnly = DateTime(
                          _endDate!.year,
                          _endDate!.month,
                          _endDate!.day,
                        );

                        final matchesDate =
                            transactionDateOnly.isAtSameMomentAs(
                              startDateOnly,
                            ) ||
                            transactionDateOnly.isAtSameMomentAs(endDateOnly) ||
                            (transactionDateOnly.isAfter(startDateOnly) &&
                                transactionDateOnly.isBefore(endDateOnly));
                        if (!matchesDate) return false;
                      }
                    } catch (e) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                // Sort transactions
                filteredTransactions = _sortTransactions(filteredTransactions);

                // Find the actual position in filtered transactions to get correct display number
                final actualIndex = filteredTransactions.indexOf(transaction);
                final displayNumber = actualIndex + 1;

                Navigator.pushNamed(
                  context,
                  RouteNames.transaksiDetail,
                  arguments: {
                    'transactionId': transaction.id,
                    'displayNumber': displayNumber,
                  },
                );
              },
            ),
            if (isAdmin)
              _sheetItem(
                icon: Icons.delete,
                title: 'Hapus Transaksi',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  // Calculate display number for delete confirmation
                  final filteredTransactions = _getFilteredTransactions();
                  final actualIndex = filteredTransactions.indexOf(transaction);
                  final displayNumber = actualIndex + 1;

                  _showDeleteConfirmation(transaction, displayNumber);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(Transaction transaction, int displayNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus transaksi #$displayNumber oleh ${transaction.namaKasir}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              _deleteTransaction(transaction.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(int transactionId) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = context.read<TransactionProvider>();
      await provider.deleteTransaction(transactionId, context: context);

      if (mounted) {
        Navigator.pop(context); // Close loading
        setState(() {
          _selectedTransactions.remove(transactionId);
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus transaksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteSelectedConfirmation() {
    final selectedCount = _selectedTransactions.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi Terpilih?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus $selectedCount transaksi yang dipilih? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              _deleteSelectedTransactions();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedTransactions() async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = context.read<TransactionProvider>();

      // Delete selected transactions
      for (final transactionId in _selectedTransactions) {
        await provider.deleteTransaction(transactionId, context: context);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        setState(() {
          _selectedTransactions.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus transaksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Riwayat Transaksi',
      currentIndex: 2,
      body: Column(
        children: [
          // Search bar and filter buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari transaksi...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date filter button
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: _showDateFilterOptions,
                      tooltip: 'Filter Tanggal',
                    ),
                    const SizedBox(width: 2),
                    // Export button
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: _showExportOptions,
                      tooltip: 'Export Laporan',
                    ),
                    const SizedBox(width: 2),
                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        context.read<TransactionProvider>().loadTransactions(
                          context: context,
                        );
                      },
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
                // Date filter indicator
                if (_dateFilter != 'semua')
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Filter: ${_getDateFilterLabel()}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _dateFilter = 'semua';
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          child: Icon(
                            Icons.clear,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                final authProvider = context.read<AuthProvider>();
                final isAdmin = authProvider.isAdmin;

                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Check if there's an error by checking if transactions is empty and not loading
                if (provider.transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Belum Ada Transaksi',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Belum ada riwayat transaksi yang tersimpan',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              RouteNames.transaksi,
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Mulai Transaksi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }

                // Filter transactions based on search query and date
                var filteredTransactions = provider.transactions.where((
                  transaction,
                ) {
                  // Apply search filter
                  if (_searchQuery.isNotEmpty) {
                    final matchesSearch =
                        transaction.id.toString().contains(_searchQuery) ||
                        transaction.namaKasir.toLowerCase().contains(
                          _searchQuery,
                        );
                    if (!matchesSearch) return false;
                  }

                  // Apply date filter
                  if (_dateFilter != 'semua') {
                    try {
                      final transactionDate = DateTime.parse(
                        transaction.tanggal,
                      );
                      final transactionDateOnly = DateTime(
                        transactionDate.year,
                        transactionDate.month,
                        transactionDate.day,
                      );

                      if (_startDate != null && _endDate != null) {
                        final startDateOnly = DateTime(
                          _startDate!.year,
                          _startDate!.month,
                          _startDate!.day,
                        );
                        final endDateOnly = DateTime(
                          _endDate!.year,
                          _endDate!.month,
                          _endDate!.day,
                        );

                        final matchesDate =
                            transactionDateOnly.isAtSameMomentAs(
                              startDateOnly,
                            ) ||
                            transactionDateOnly.isAtSameMomentAs(endDateOnly) ||
                            (transactionDateOnly.isAfter(startDateOnly) &&
                                transactionDateOnly.isBefore(endDateOnly));
                        if (!matchesDate) return false;
                      }
                    } catch (e) {
                      return false;
                    }
                  }

                  return true;
                }).toList();

                // Sort transactions
                filteredTransactions = _sortTransactions(filteredTransactions);

                // Reset to page 1 if current page is out of bounds after filtering
                final totalPages = _getTotalPages(filteredTransactions.length);
                if (_currentPage > totalPages && totalPages > 0) {
                  setState(() {
                    _currentPage = totalPages;
                  });
                }

                // Get paginated transactions
                final paginatedTransactions = _getPaginatedTransactions(
                  filteredTransactions,
                );

                if (filteredTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Transaksi Tidak Ditemukan'
                              : 'Tidak Ada Transaksi',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada transaksi dengan kata kunci "$_searchQuery"'
                              : 'Tidak ada transaksi pada periode ini',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (_searchQuery.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Hapus Pencarian'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _dateFilter = 'semua';
                                _startDate = null;
                                _endDate = null;
                              });
                            },
                            icon: const Icon(Icons.date_range),
                            label: const Text('Reset Filter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Batch selection interface
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value:
                                _selectedTransactions.length ==
                                paginatedTransactions.length,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  // Select all transactions on current page
                                  _selectedTransactions = paginatedTransactions
                                      .map((t) => t.id)
                                      .toSet();
                                } else {
                                  // Deselect all transactions
                                  _selectedTransactions.clear();
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedTransactions.isEmpty
                                  ? 'Pilih semua transaksi (${paginatedTransactions.length})'
                                  : 'Terpilih ${_selectedTransactions.length} dari ${paginatedTransactions.length} transaksi',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_selectedTransactions.isNotEmpty && isAdmin)
                            IconButton(
                              onPressed: _showDeleteSelectedConfirmation,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Hapus yang dipilih',
                            ),
                        ],
                      ),
                    ),
                    // Transaction list
                    Expanded(
                      child: ListView.builder(
                        itemCount: paginatedTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = paginatedTransactions[index];
                          return _buildTransactionCard(
                            transaction,
                            index,
                            filteredTransactions,
                          );
                        },
                      ),
                    ),
                    // Pagination controls
                    _buildPaginationControls(totalPages),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
