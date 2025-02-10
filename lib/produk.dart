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
  bool isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await _supabase.from('produk').select();
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _filteredProducts = _products;
        isLoading = false;
      });
    } catch (e) {
      _showError('Terjadi kesalahan saat mengambil data: $e');
    }
  }

  void _filterProducts() {
  String query = _searchController.text.toLowerCase();
  setState(() {
    _filteredProducts = _products.where((product) {
      String namaProduk = product['nama_produk'].toLowerCase();
      String hargaProduk = product['harga'].toString();

      return namaProduk.contains(query) || hargaProduk.contains(query);
    }).toList();
  });
}


  Future<void> _addOrUpdateProduct({Map<String, dynamic>? product}) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController namaProdukController =
        TextEditingController(text: product?['nama_produk'] ?? '');
    final TextEditingController hargaController =
        TextEditingController(text: product?['harga']?.toString() ?? '');
    final TextEditingController stokController =
        TextEditingController(text: product?['stok']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaProdukController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) =>
                      value!.isEmpty ? 'Nama produk tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: hargaController,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Harga tidak boleh kosong';
                    return double.tryParse(value) == null
                        ? 'Masukkan angka yang valid'
                        : null;
                  },
                ),
                TextFormField(
                  controller: stokController,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) return 'Stok tidak boleh kosong';
                    return int.tryParse(value) == null
                        ? 'Masukkan angka yang valid'
                        : null;
                  },
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
                  foregroundColor: Colors.white,
                ),),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final String namaProduk = namaProdukController.text;
                  final double harga = double.parse(hargaController.text);
                  final int stok = int.parse(stokController.text);

                  final existingProduct = await _supabase
                      .from('produk')
                      .select()
                      .eq('nama_produk', namaProduk)
                      .maybeSingle();

                  if (existingProduct != null &&
                      (product == null ||
                          existingProduct['id_produk'] !=
                              product['id_produk'])) {
                    Navigator.of(context)
                        .pop();
                    Future.delayed(Duration(milliseconds: 300), () {
                      _showError('Produk dengan nama tersebut sudah ada.');
                    });
                    return;
                  }

                  if (product == null) {
                    await _supabase.from('produk').insert({
                      'nama_produk': namaProduk,
                      'harga': harga,
                      'stok': stok,
                    });
                  } else {
                    await _supabase.from('produk').update({
                      'nama_produk': namaProduk,
                      'harga': harga,
                      'stok': stok,
                    }).eq('id_produk', product['id_produk']);
                  }
                  Navigator.of(context).pop();
                  _fetchProducts();
                }
              },
              child: const Text('Simpan'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              )
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await _supabase.from('produk').delete().eq('id_produk', id);
      _fetchProducts();
    } catch (e) {
      _showError('Gagal menghapus produk: $e');
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),),
            TextButton(
              onPressed: () {
                _deleteProduct(id);
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 216, 18, 4),
                foregroundColor: Colors.white
              )
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Produk',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Card(
                        child: ListTile(
                          title: Text(product['nama_produk']),
                          subtitle: Text(
                              'Rp${product['harga']} - Stok: ${product['stok']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xff16C47F)),
                                  onPressed: () =>
                                      _addOrUpdateProduct(product: product)),
                              IconButton(
                                  icon: const Icon(Icons.delete, color: Color(0xffF93827)),
                                  onPressed: () =>
                                      _confirmDelete(product['id_produk'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateProduct(),
        child: const Icon(Icons.add, color: Colors.white,),
        backgroundColor: Color(0xff16C47F),
      ),
      backgroundColor: Color(0xffEDF4C2),
    );
  }
}
