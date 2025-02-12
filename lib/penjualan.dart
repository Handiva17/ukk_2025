import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';

class PenjualanPage extends StatefulWidget {
  const PenjualanPage({Key? key}) : super(key: key);

  @override
  _PenjualanPageState createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NumberFormat currencyFormat = NumberFormat.decimalPattern('id');

  List<Map<String, dynamic>> _cart = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _customers = [];
  String? _selectedCustomer;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCustomers();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _supabase.from('produk').select();
      setState(() {
        _products = List<Map<String, dynamic>>.from(response as List<dynamic>);
      });
    } catch (error) {
      debugPrint('Error fetching products: $error');
    }
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await _supabase.from('pelanggan').select();
      setState(() {
        _customers = List<Map<String, dynamic>>.from(response as List<dynamic>);
      });
    } catch (error) {
      debugPrint('Error fetching customers: $error');
    }
  }

  Future<void> _generatePDF(String namaPelanggan, String formattedDate,
    List<Map<String, dynamic>> detailPenjualan, double totalHarga) async {
  final pdf = pw.Document();
  final currencyFormat = NumberFormat('#,##0', 'id_ID');

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Judul Struk
            pw.Center(
              child: pw.Text('WARTEG KOMPLIT',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text('Jl. Waringin, Slorok, Kec. Kromengan, Kab. Malang',
                  style: pw.TextStyle(fontSize: 12)),
            ),
            pw.Center(
              child: pw.Text('Telp: 089-541-231-0212',
                  style: pw.TextStyle(fontSize: 12)),
            ),
            pw.SizedBox(height: 5),
            pw.Divider(),
            pw.SizedBox(height: 5),

            // Informasi Pelanggan & Tanggal
            pw.Text('Nama Pelanggan: $namaPelanggan',
                style: pw.TextStyle(fontSize: 12)),
            pw.Text('Tanggal: $formattedDate', style: pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 10),

            // Header Tabel
            pw.Table(
              border: pw.TableBorder.all(width: 1),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEEEE)),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Produk', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Jumlah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Subtotal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...detailPenjualan.map((detail) => pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(detail['produk']['nama_produk'])),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${detail['jumlah_produk']}')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('Rp ${currencyFormat.format(detail['subtotal'].toInt())}')),
                    ])),
              ],
            ),
            pw.SizedBox(height: 10),

            // Total Harga
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Harga:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Rp ${currencyFormat.format(totalHarga.toInt())}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),

            // Footer
            pw.Center(
              child: pw.Text('Terima Kasih Sudah Berbelanja!',
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ),
          ],
        );
      },
    ),
  );

  // Simpan file pada web
  final Uint8List pdfBytes = await pdf.save();
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'struk_pembelian.pdf')
    ..click();

  html.Url.revokeObjectUrl(url);
}

  void _addToCart(Map<String, dynamic> product) async {
    if (product['stok'] <= 0) return;

    setState(() {
      final index =
          _cart.indexWhere((item) => item['id_produk'] == product['id_produk']);
      if (index != -1) {
        _cart[index]['quantity'] += 1;
      } else {
        _cart.add({...product, 'quantity': 1});
      }
    });

    try {
      final newStock = product['stok'] - 1;
      await _supabase
          .from('produk')
          .update({'stok': newStock}).eq('id_produk', product['id_produk']);

      setState(() {
        product['stok'] = newStock;
      });
    } catch (error) {
      debugPrint('Error updating stock: $error');
    }

    _calculateTotal();
  }

  void _updateCart(Map<String, dynamic> product, int quantity) async {
    setState(() {
      final index =
          _cart.indexWhere((item) => item['id_produk'] == product['id_produk']);
      if (index != -1) {
        if (quantity > 0) {
          // Hitung selisih pengurangan stok
          int diff = _cart[index]['quantity'] - quantity;

          // Update jumlah produk dalam keranjang
          _cart[index]['quantity'] = quantity;

          // Tambahkan kembali stok di daftar produk
          final productIndex = _products
              .indexWhere((item) => item['id_produk'] == product['id_produk']);
          if (productIndex != -1) {
            _products[productIndex]['stok'] += diff;
          }
        } else {
          // Jika jumlah menjadi 0, hapus dari keranjang dan kembalikan seluruh stok
          final removedQuantity = _cart[index]['quantity'];
          _cart.removeAt(index);

          final productIndex = _products
              .indexWhere((item) => item['id_produk'] == product['id_produk']);
          if (productIndex != -1) {
            _products[productIndex]['stok'] += removedQuantity;
          }
        }
      }
      _calculateTotal();
    });

    try {
      // Update stok ke database
      await _supabase.from('produk').update({
        'stok': product['stok'],
      }).eq('id_produk', product['id_produk']);
    } catch (error) {
      debugPrint('Error updating stock: $error');
    }
  }

  void _calculateTotal() {
    double total = _cart.fold(
      0,
      (sum, item) => sum + (item['harga'] * item['quantity']),
    );
    // if (_selectedCustomer != null && _selectedCustomer != 'pelanggan biasa') {
    //   total -= 1000; // Diskon Rp 1000
    // }
    setState(() {
      _totalPrice = total;
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    try {
      _calculateTotal(); // Pastikan total dihitung sebelum transaksi

      final response = await _supabase.from('penjualan').insert({
        'tanggal_penjualan': DateTime.now().toIso8601String(),
        'total_harga': _totalPrice,
        'id_pelanggan': int.parse(_selectedCustomer!),
      }).select();
      final penjualanId = response[0]['id_penjualan'];
      final namaPelanggan = _customers.firstWhere((c) =>
          c['id_pelanggan'].toString() == _selectedCustomer)['nama_pelanggan'];
      final formattedDate =
          DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());

      List<Map<String, dynamic>> detailPenjualan = [];
      for (final item in _cart) {
        await _supabase.from('detail_penjualan').insert({
          'id_penjualan': penjualanId,
          'id_produk': item['id_produk'],
          'jumlah_produk': item['quantity'],
          'subtotal': item['harga'] * item['quantity'],
        });

        await _supabase.from('produk').update({
          'stok': item['stok'] - item['quantity'],
        }).eq('id_produk', item['id_produk']);

        detailPenjualan.add({
          'produk': {'nama_produk': item['nama_produk']},
          'jumlah_produk': item['quantity'],
          'subtotal': item['harga'] * item['quantity'],
        });
      }

      // Simpan total harga sebelum mengosongkan state
      final totalHargaTransaksi = _totalPrice;

      setState(() {
        _cart.clear();
        _selectedCustomer = null;
        _totalPrice = 0; // Reset total setelah transaksi
      });

      await _fetchProducts();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Transaksi Berhasil'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nama Pelanggan: $namaPelanggan'),
                const SizedBox(height: 8),
                Text('Tanggal: $formattedDate'),
                const SizedBox(height: 8),
                Text(
                    'Total: Rp ${currencyFormat.format(totalHargaTransaksi.toInt())}'),
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
              child: const Text('Simpan'),
              style: TextButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),
            TextButton(
              onPressed: () async {
                await _generatePDF(namaPelanggan, formattedDate,
                    detailPenjualan, totalHargaTransaksi);
              },
              child: const Text('Unduh Struk'),
              style: TextButton.styleFrom(backgroundColor: const Color.fromARGB(255, 42, 75, 223), foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    } catch (error) {
      debugPrint('Error during checkout: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat transaksi.')),
      );
    }
  }

  Widget _buildProductList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Icon(Icons.fastfood, color: Color(0xff5F9DF7)),
            title: Text(
              product['nama_produk'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Harga: Rp ${currencyFormat.format(product['harga'])}'),
                Text('Stok: ${product['stok']}'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: product['stok'] > 0 ? () => _addToCart(product) : null,
              child: const Text('Tambah'),
              style: TextButton.styleFrom(
                backgroundColor:
                    product['stok'] > 0 ? Color(0xff16C47F) : Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        ..._cart.map((item) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(item['nama_produk']),
              subtitle: Text(
                  'Harga: Rp ${currencyFormat.format(item['harga'])} x ${item['quantity']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _updateCart(item, item['quantity'] - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _updateCart(item, item['quantity'] + 1),
                  ),
                ],
              ),
            ),
          );
        }),
        ListTile(
          title: const Text(
            'Total Harga',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          trailing: Text(
            'Rp ${currencyFormat.format(_totalPrice.toInt())}',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        ElevatedButton(
          onPressed: _checkout,
          child: const Text('Bayar'),
          style: TextButton.styleFrom(
            backgroundColor: Color(0xff16C47F),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Pilih Pelanggan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  DropdownButton<String>(
                    value: _selectedCustomer,
                    hint: const Text('Pilih Pelanggan'),
                    isExpanded: true,
                    items: [
                      ..._customers.map((customer) {
                        return DropdownMenuItem(
                          value: customer['id_pelanggan'].toString(),
                          child: Text(customer['nama_pelanggan']),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                        _calculateTotal();
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            const Text(
              'Daftar Produk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            _buildProductList(),
            const Divider(),
            const Text(
              'Keranjang Belanja',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            _buildCart(),
          ],
        ),
      ),
      backgroundColor: Color(0xffFFF5E4),
    );
  }
}