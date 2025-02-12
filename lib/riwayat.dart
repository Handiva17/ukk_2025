import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RiwayatPage extends StatefulWidget {
  final VoidCallback? onRefresh;
  const RiwayatPage({Key? key, this.onRefresh}) : super(key: key);

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NumberFormat currencyFormat = NumberFormat.decimalPattern('id');
  List<Map<String, dynamic>> _transactionHistory = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchTransactionHistory();
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      final response = await _supabase.from('penjualan').select('''
        id_penjualan,
        tanggal_penjualan,
        total_harga,
        id_pelanggan,
        pelanggan (nama_pelanggan),
        detail_penjualan (
          id_produk,
          jumlah_produk,
          subtotal,
          produk (nama_produk, harga)
        )
      ''').order('id_penjualan', ascending: false);

      if (!mounted) return;

      setState(() {
        _transactionHistory =
            List<Map<String, dynamic>>.from(response as List<dynamic>);
        _filteredTransactions = _transactionHistory;
      });
    } catch (error) {
      debugPrint('Error fetching transaction history: $error');
    }
  }

  void _filterTransactions(String query) {
    setState(() {
      _filteredTransactions = _transactionHistory.where((transaction) {
        final transactionNumber =
            '${_transactionHistory.length - _transactionHistory.indexOf(transaction)}';
        final bool isTransactionMatch =
            query.trim().isNotEmpty && transactionNumber == query.trim();

        final productNames = transaction['detail_penjualan']
            .map((detail) =>
                detail['produk']['nama_produk'].toString().toLowerCase())
            .join(' ');

        final String namaPelanggan =
            transaction['pelanggan']['nama_pelanggan']?.toLowerCase() ?? '';

        return isTransactionMatch ||
            productNames.contains(query.toLowerCase()) ||
            namaPelanggan.contains(query.toLowerCase());
      }).toList();
    });
  }

  String _formatDateTime(String dateTime) {
    final date = DateTime.parse(dateTime);
    return DateFormat('dd MMMM yyyy').format(date);
  }

  void _showTransactionDetails(
      BuildContext context, Map<String, dynamic> transaction) {
    final formattedDate = _formatDateTime(transaction['tanggal_penjualan']);
    final detailPenjualan = List<Map<String, dynamic>>.from(
        transaction['detail_penjualan'] as List<dynamic>);
    final String namaPelanggan =
        transaction['pelanggan']['nama_pelanggan'] ?? 'Tidak diketahui';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Detail Transaksi #${_transactionHistory.length - _transactionHistory.indexOf(transaction)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Pelanggan: $namaPelanggan'),
              const SizedBox(height: 8),
              Text('Tanggal: $formattedDate'),
              const SizedBox(height: 8),
              Text(
                  'Total: Rp ${currencyFormat.format(transaction['total_harga'].toInt())}'),
              const SizedBox(height: 8),
              const Text('Detail Produk:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...detailPenjualan
                  .map((detail) => ListTile(
                        title: Text(detail['produk']['nama_produk']),
                        subtitle: Text(
                            'Jumlah: ${detail['jumlah_produk']} | Subtotal: Rp ${currencyFormat.format(detail['subtotal'].toInt())}'),
                      ))
                  .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFF5E4),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Transaksi',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterTransactions,
            ),
          ),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(
                    child: Text('Belum ada riwayat transaksi.'),
                  )
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      final formattedDate =
                          _formatDateTime(transaction['tanggal_penjualan']);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading:
                              Icon(Icons.history_edu, color: Color(0xff5F9DF7)),
                          title: Text(
                              'Transaksi #${_transactionHistory.length - _transactionHistory.indexOf(transaction)}'),
                          subtitle: Text(
                            'Tanggal: $formattedDate\nTotal: Rp ${currencyFormat.format(transaction['total_harga'])}',
                          ),
                          onTap: () =>
                              _showTransactionDetails(context, transaction),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}