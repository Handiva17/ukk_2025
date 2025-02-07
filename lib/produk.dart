import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({Key? key}) : super(key: key);

  @override
  _ProdukPageState createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
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

  Future<void> _addProduct(
      String nama_produk, String harga, String stok) async {
    try {
      await _supabase
          .from('produk')
          .insert({'nama_produk': nama_produk, 'harga': harga, 'stok': stok});
      _fetchProducts();
    } catch (error) {
      debugPrint('Error adding products: $error');
    }
  }

  Future<void> _editProduct(
      int id, String nama_produk, String harga, String stok) async {
    try {
      await _supabase
          .from('produk')
          .update({'nama_produk': nama_produk, 'harga': harga}).eq('id', id);
      _fetchProducts();
    } catch (error) {
      debugPrint('Error editing products: $error');
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await _supabase.from('produk').delete().eq('id', id);
      _fetchProducts();
    } catch (error) {
      debugPrint('Error deleting products: $error');
    }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penghapusan'),
        content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 177, 255),
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteProduct(id);
              Navigator.of(context).pop();
            },
            child: const Text('Hapus'),
            style: TextButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showProductDialog({Map<String, dynamic>? produk}) {
    final TextEditingController nama_produkController =
        TextEditingController(text: produk?['nama_produk'] ?? '');
    final TextEditingController hargaController =
        TextEditingController(text: produk?['harga'] ?? '');
    final TextEditingController stokController =
        TextEditingController(text: produk?['stok'] ?? '');
    final _formKey = GlobalKey<FormState>();


    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(produk == null ? 'Tambah Produk' : 'Edit Produk'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nama_produkController,
                      decoration:
                          const InputDecoration(labelText: 'Nama Produk'),
                      validator: (value) =>
                          value!.isEmpty ? 'Produk tidak boleh kosong' : null,
                    ),
                    TextFormField(
                      controller: hargaController,
                      decoration: InputDecoration(labelText: 'Harga'),
                      validator: (value) =>
                          value!.isEmpty ? 'Harga tidak boleh kosong' : null,
                    ),
                    TextFormField(
                      controller: stokController,
                      decoration: InputDecoration(labelText: 'Stok'),
                      validator: (value) =>
                          value!.isEmpty ? 'Stok tidak boleh kosong' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (produk == null) {
                        _addProduct(nama_produkController.text,
                            hargaController.text, stokController.text);
                      } else {
                        _editProduct(produk['id'], nama_produkController.text,
                            hargaController.text, stokController.text);
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(produk == null ? 'Tambah' : 'Simpan'),
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final produk = _products[index];
          return ListTile(
            title: Text(produk['nama_produk']),
            titleTextStyle: TextStyle(
              fontSize: 20.0,
            ),
            subtitle: Text(produk['harga']),
            subtitleTextStyle: TextStyle(fontSize: 18.0),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xff16C47F)),
                  onPressed: () => _showProductDialog(produk: produk),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xffF93827)),
                  onPressed: () => _showDeleteConfirmation(produk['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xff16C47F),
      ),
      backgroundColor: Color(0xffEDF4C2),
    );
  }
}
