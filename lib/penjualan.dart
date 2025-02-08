import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PenjualanPage extends StatefulWidget {
  @override
  _PenjualanPageState createState() => _PenjualanPageState();
}

class _PenjualanPageState extends State<PenjualanPage> {
  final supabase = Supabase.instance.client;
  int? selectedPelanggan;
  List<Map<String, dynamic>> produkList = [];
  List<Map<String, dynamic>> keranjang = [];
  List<Map<String, dynamic>> pelangganList = [];

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  Future<void> _fetchProduk() async {
    final response = await supabase.from('produk').select();
    if (response != null) {
      setState(() {
        produkList = List<Map<String, dynamic>>.from(response);
      });
    } else {
      print('Data produk kosong!');
    }
  }

  Future<void> _fetchPelanggan() async {
    final response = await supabase.from('pelanggan').select('*');
    setState(() {
      pelangganList = List<Map<String, dynamic>>.from(response);
    });
  }

  void tambahKeKeranjang(Map<String, dynamic> produk) {
    setState(() {
      var itemIndex = keranjang
          .indexWhere((element) => element['id_produk'] == produk['id_produk']);

      if (itemIndex != -1) {
        keranjang[itemIndex]['jumlah']++;
        keranjang[itemIndex]['subtotal'] = keranjang[itemIndex]['jumlah'] *
            (keranjang[itemIndex]['harga'] ?? 0.0);
      } else {
        keranjang.add({
          'id_produk': produk['id_produk'],
          'nama_produk': produk['nama_produk'] ?? 'Produk Tidak Diketahui',
          'harga': (produk['harga'] ?? 0.0).toDouble(),
          'jumlah': 1,
          'subtotal': (produk['harga'] ?? 0.0).toDouble(),
        });
      }
    });
  }

  void kurangiDariKeranjang(Map<String, dynamic> produk) {
    setState(() {
      var item = keranjang.firstWhere(
        (element) => element['id_produk'] == produk['id_produk'],
        orElse: () => {},
      );
      if (item.isNotEmpty) {
        if (item['jumlah'] > 1) {
          item['jumlah']--;
          item['subtotal'] = item['jumlah'] * item['harga'];
        } else {
          keranjang.removeWhere(
              (element) => element['id_produk'] == produk['id_produk']);
        }
      }
    });
  }

  Future<void> _prosesBayar() async {
    if (keranjang.isEmpty || selectedPelanggan == null) return;

    final totalHarga = keranjang.fold(
        0.0, (sum, item) => sum + (item['subtotal']?.toDouble() ?? 0.0));
    final response = await supabase.from('penjualan').insert({
      'tanggal_penjualan': DateTime.now().toIso8601String(),
      'total_harga': totalHarga,
      'id_pelanggan': selectedPelanggan,
    }).select();

    final idPenjualan = response.first['id_penjualan'];
    for (var item in keranjang) {
      await supabase.from('detail_penjualan').insert({
        'id_penjualan': idPenjualan,
        'id_produk': item['id_produk'],
        'jumlah_produk': item['jumlah'],
        'subtotal': item['subtotal'],
      });
      await supabase.from('produk').update({
        'stok': supabase.rpc('kurangi_stok',
            params: {'id_produk': item['id_produk'], 'jumlah': item['jumlah']})
      }).eq('id_produk', item['id_produk']);
    }
    setState(() {
      keranjang.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout Penjualan')),
      body: Column(
        children: [
          DropdownButton<int>(
            hint: Text('Pilih Pelanggan'),
            value: selectedPelanggan,
            items: pelangganList.map((pelanggan) {
              return DropdownMenuItem<int>(
                value: pelanggan['id_pelanggan'],
                child: Text(pelanggan['nama_pelanggan'] ?? 'Tanpa Nama'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPelanggan = value;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: produkList.length,
              itemBuilder: (context, index) {
                final produk = produkList[index];
                return ListTile(
                  title: Text(produk['nama_produk']),
                  subtitle: Text('Harga: ${produk['harga']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () => kurangiDariKeranjang(produk),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => tambahKeKeranjang(produk),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: keranjang.length,
              itemBuilder: (context, index) {
                final item = keranjang[index];
                return ListTile(
                  title: Text(item['nama_produk']),
                  subtitle: Text(
                      'Jumlah: ${item['jumlah']} - Total: ${item['subtotal']}'),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _prosesBayar,
            child: Text('Bayar'),
          ),
        ],
      ),
    );
  }
}
