import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:typed_data';
import 'dart:io';
import '../models/transaction_model.dart';
import '../services/wifi_service.dart';

class PdfReceiptService {
  static Future<Uint8List> generateReceipt(
    Transaction transaction,
    int displayNumber,
  ) async {
    final pdf = pw.Document();
    final regularFont = await PdfGoogleFonts.nunitoRegular();
    final boldFont = await PdfGoogleFonts.nunitoBold();

    // Generate transaction number
    final transactionNumber = _generateTransactionNumber();

    // Get WiFi info synchronously before creating PDF
    final wifiInfo = await _getWiFiInfo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section - Professional
              _buildHeader(boldFont, regularFont),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF000000)),
              pw.SizedBox(height: 12),

              // Transaction Info - Clear and organized
              _buildTransactionInfo(
                transaction,
                displayNumber,
                transactionNumber,
                boldFont,
                regularFont,
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColor.fromInt(0xFF666666)),
              pw.SizedBox(height: 12),

              // Items Table - Professional layout
              _buildItemsTable(transaction.items, boldFont, regularFont),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: PdfColor.fromInt(0xFF666666)),
              pw.SizedBox(height: 12),

              // Total Section - Bold and clear
              _buildTotalSection(transaction.totalHarga, boldFont, regularFont),
              pw.SizedBox(height: 16),

              // WiFi Info (if available) - Subtle design
              if (wifiInfo['hasWiFi'] == true) ...[
                pw.Divider(
                  thickness: 1,
                  color: PdfColor.fromInt(0xFF666666),
                  borderStyle: pw.BorderStyle.dashed,
                ),
                pw.SizedBox(height: 12),
                _buildWiFiInfoStatic(
                  wifiInfo['name'] ?? 'Kasir-WiFi',
                  wifiInfo['password'] ?? 'Kasir123456',
                  regularFont,
                  boldFont,
                ),
                pw.SizedBox(height: 12),
              ],

              // Footer - Professional closing
              pw.Divider(
                thickness: 1,
                color: PdfColor.fromInt(0xFF666666),
                borderStyle: pw.BorderStyle.dashed,
              ),
              pw.SizedBox(height: 12),
              _buildFooter(regularFont, boldFont),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<Map<String, dynamic>> _getWiFiInfo() async {
    try {
      final hasWiFi = await WiFiService.hasWiFiSettings();
      if (hasWiFi) {
        final wifiSettings = await WiFiService.getWiFiSettings();
        return {
          'hasWiFi': true,
          'name': wifiSettings['name'],
          'password': wifiSettings['password'],
        };
      }
    } catch (e) {
      // Ignore WiFi errors
    }
    return {'hasWiFi': false};
  }

  static pw.Widget _buildHeader(pw.Font boldFont, pw.Font regularFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Store name - Large and bold
        pw.Text(
          'KASIR APP',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
            letterSpacing: 2,
          ),
        ),
        pw.SizedBox(height: 4),
        // Receipt type - Medium size
        pw.Text(
          'STRUK PEMBAYARAN',
          style: pw.TextStyle(fontSize: 14, font: boldFont, letterSpacing: 1.5),
        ),
        pw.SizedBox(height: 4),
        // Additional store info (optional)
        pw.Text(
          'Terima kasih atas pembelian Anda',
          style: pw.TextStyle(
            fontSize: 9,
            font: regularFont,
            color: PdfColor.fromInt(0xFF666666),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionInfo(
    Transaction transaction,
    int displayNumber,
    String transactionNumber,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Transaction number - Prominent
        _buildInfoRow(
          'NO. TRANSAKSI',
          transactionNumber,
          boldFont,
          regularFont,
          isHeader: true,
        ),
        pw.SizedBox(height: 6),
        // Date - Clear formatting
        _buildInfoRow(
          'TANGGAL',
          _formatDate(transaction.tanggal),
          boldFont,
          regularFont,
        ),
        pw.SizedBox(height: 6),
        // Cashier name
        _buildInfoRow(
          'KASIR',
          transaction.namaKasir.trim().isNotEmpty
              ? transaction.namaKasir.toUpperCase()
              : 'TIDAK DIKETAHUI',
          boldFont,
          regularFont,
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font boldFont,
    pw.Font regularFont, {
    bool isHeader = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: isHeader ? 11 : 10,
            color: PdfColor.fromInt(0xFF666666),
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: isHeader ? 11 : 10,
              color: PdfColor.fromInt(0xFF000000),
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(
    List<TransactionItem> items,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Table Header - Professional
        pw.Text(
          'RINCIAN PEMBELIAN',
          style: pw.TextStyle(font: boldFont, fontSize: 11, letterSpacing: 0.5),
        ),
        pw.SizedBox(height: 8),

        // Column headers with better spacing
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFF333333),
                width: 1,
              ),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 6,
                child: pw.Text(
                  'ITEM',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF000000),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: 25,
                child: pw.Text(
                  'QTY',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF000000),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                width: 55,
                child: pw.Text(
                  'HARGA',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF000000),
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),

        // Items list with better layout
        ...items.map(
          (item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Product name - more space and better wrapping
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.only(right: 4),
                    child: pw.Text(
                      item.namaProduk,
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 8,
                        color: PdfColor.fromInt(0xFF000000),
                      ),
                      maxLines: 3,
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                // Quantity - centered with proper width
                pw.Container(
                  width: 25,
                  child: pw.Text(
                    '${item.quantity}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 8,
                      color: PdfColor.fromInt(0xFF000000),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(width: 12),
                // Unit price - right aligned with compact format
                pw.Container(
                  width: 55,
                  child: pw.Text(
                    _formatCurrencyCompact(item.harga),
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 7,
                      color: PdfColor.fromInt(0xFF666666),
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalSection(
    int totalHarga,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Column(
      children: [
        // Subtotal line (can add tax, discount here later)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SUBTOTAL',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 11,
                color: PdfColor.fromInt(0xFF666666),
              ),
            ),
            pw.Text(
              _formatCurrency(totalHarga),
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 11,
                color: PdfColor.fromInt(0xFF666666),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),

        // Total - Large and prominent
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF000000),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TOTAL',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                  color: PdfColors.white,
                  letterSpacing: 1,
                ),
              ),
              pw.Text(
                _formatCurrency(totalHarga),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  color: PdfColors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 8),

        // Payment method (can be added later)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'METODE PEMBAYARAN',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 9,
                color: PdfColor.fromInt(0xFF666666),
              ),
            ),
            pw.Text(
              'TUNAI',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 9,
                color: PdfColor.fromInt(0xFF000000),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildWiFiInfoStatic(
    String wifiName,
    String wifiPassword,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFCCCCCC), width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // WiFi header
          pw.Row(
            children: [
              pw.Text('📶', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(width: 6),
              pw.Text(
                'WIFI GRATIS TERSEDIA',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 9,
                  color: PdfColor.fromInt(0xFF000000),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // Network info
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 60,
                child: pw.Text(
                  'Network',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ),
              pw.Text(
                ': ',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF666666),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  wifiName,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF000000),
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),

          // Password info
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 60,
                child: pw.Text(
                  'Password',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ),
              pw.Text(
                ': ',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 8,
                  color: PdfColor.fromInt(0xFF666666),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  wifiPassword,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColor.fromInt(0xFF000000),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font regularFont, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Thank you message - centered
        pw.Text(
          'TERIMA KASIH',
          style: pw.TextStyle(font: boldFont, fontSize: 12, letterSpacing: 1.5),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Atas kunjungan Anda',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 9,
            color: PdfColor.fromInt(0xFF666666),
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 12),

        // Store policy - centered
        pw.Text(
          'Barang yang sudah dibeli tidak dapat dikembalikan',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 7,
            color: PdfColor.fromInt(0xFF999999),
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'kecuali ada kesalahan dari pihak toko',
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 7,
            color: PdfColor.fromInt(0xFF999999),
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 12),

        // Branding - centered
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: PdfColor.fromInt(0xFFCCCCCC),
              width: 0.5,
            ),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(
            'Powered by KASIR APP',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 7,
              color: PdfColor.fromInt(0xFF666666),
              letterSpacing: 0.5,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static String _generateTransactionNumber() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 10000000000;
    return '#${random.toString().padLeft(10, '0')}';
  }

  static String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String _formatCurrencyCompact(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final wibDate = date.isUtc ? date.toLocal() : date;
      return DateFormat('dd/MM/yyyy HH:mm').format(wibDate);
    } catch (e) {
      return dateString;
    }
  }

  static Future<void> printReceipt(
    Transaction transaction,
    int displayNumber, {
    BuildContext? context,
    bool useExternalApp = true,
  }) async {
    try {
      final pdfData = await generateReceipt(transaction, displayNumber);

      if (useExternalApp) {
        // Save PDF to temporary file and open with external app
        await _saveAndOpenPdf(
          pdfData,
          'Struk_Transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );

        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Struk berhasil dibuka di aplikasi PDF'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Try direct printing to printer
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) => pdfData,
          name: 'Struk_Transaksi_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Struk dikirim ke printer'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      throw Exception('Gagal mencetak struk: $e');
    }
  }

  static Future<void> printDirectly(
    Transaction transaction,
    int displayNumber, {
    BuildContext? context,
  }) async {
    await printReceipt(
      transaction,
      displayNumber,
      context: context,
      useExternalApp: false,
    );
  }

  static Future<void> openInExternalApp(
    Transaction transaction,
    int displayNumber, {
    BuildContext? context,
  }) async {
    await printReceipt(
      transaction,
      displayNumber,
      context: context,
      useExternalApp: true,
    );
  }

  static Future<void> _saveAndOpenPdf(
    Uint8List pdfData,
    String fileName,
  ) async {
    try {
      // Try to save to device-specific folder
      Directory? saveDir;

      if (Platform.isAndroid) {
        // For Android, try to access Downloads folder
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to Downloads folder
          saveDir = Directory('/storage/emulated/0/Download');
          if (!await saveDir.exists()) {
            saveDir = Directory('/storage/emulated/0/Downloads');
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, save to app's Documents directory
        // iOS doesn't allow direct access to Downloads like Android
        saveDir = await getApplicationDocumentsDirectory();

        // Create a subfolder for receipts
        final receiptsDir = Directory('${saveDir.path}/Struk');
        if (!await receiptsDir.exists()) {
          await receiptsDir.create(recursive: true);
        }
        saveDir = receiptsDir;
      }

      // Fallback to app documents directory if specific folder fails
      if (saveDir == null || !await saveDir.exists()) {
        saveDir = await getApplicationDocumentsDirectory();
      }

      // Create directory if it doesn't exist
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'Struk_${timestamp.toString()}.pdf';
      final file = File('${saveDir.path}/$uniqueFileName');

      // Save PDF file
      await file.writeAsBytes(pdfData);

      // Show success message with file location
      debugPrint('PDF saved to: ${file.path}');

      // Open file with external app
      final result = await OpenFile.open(file.path);

      if (result.type == ResultType.error) {
        throw Exception('Tidak dapat membuka file PDF: ${result.message}');
      }
    } catch (e) {
      throw Exception('Gagal menyimpan atau membuka PDF: $e');
    }
  }

  static Future<void> shareReceipt(
    Transaction transaction,
    int displayNumber,
  ) async {
    try {
      final pdfData = await generateReceipt(transaction, displayNumber);
      await Printing.sharePdf(
        bytes: pdfData,
        filename:
            'Struk_Transaksi_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      throw Exception('Gagal membagikan struk: $e');
    }
  }
}
