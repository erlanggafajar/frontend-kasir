import 'package:flutter/material.dart';
import '../../core/widgets/app_scaffold.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to riwayat screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/riwayat');
    });

    return AppScaffold(
      title: 'Riwayat Transaksi',
      currentIndex: 2,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
