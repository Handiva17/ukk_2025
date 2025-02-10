import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PelangganPage extends StatefulWidget {
  const PelangganPage({Key? key}) : super(key: key);

  @override
  _PelangganPageState createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pelanggan = [];
  bool isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPelanggan = [];

  @override
  void initState() {
    super.initState();
    _fetchPelanggan();
    _searchController.addListener(_filterPelanggan);
  }

  Future<void> _fetchPelanggan() async {
    try {
      final response = await _supabase.from('pelanggan').select();
      setState(() {
        _pelanggan = List<Map<String, dynamic>>.from(response);
        _filteredPelanggan = _pelanggan;
        isLoading = false;
      });
    } catch (e) {
      _showError('Terjadi kesalahan saat mengambil data: $e');
    }
  }

  void _filterPelanggan() {
  String query = _searchController.text.toLowerCase();
  setState(() {
    _filteredPelanggan = _pelanggan.where((pelanggan) {
      String namaPelanggan = pelanggan['nama_pelanggan'].toLowerCase();
      String alamat = pelanggan['alamat'].toLowerCase();
      String nomorTelepon = pelanggan['nomor_telepon'].toString();

      return namaPelanggan.contains(query) || 
             alamat.contains(query) || 
             nomorTelepon.contains(query);
    }).toList();
  });
}


  Future<void> _addOrUpdatePelanggan({Map<String, dynamic>? pelanggan}) async {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController namaController =
        TextEditingController(text: pelanggan?['nama_pelanggan'] ?? '');
    final TextEditingController alamatController =
        TextEditingController(text: pelanggan?['alamat'] ?? '');
    final TextEditingController teleponController =
        TextEditingController(text: pelanggan?['nomor_telepon'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(pelanggan == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration:
                      const InputDecoration(labelText: 'Nama Pelanggan'),
                  validator: (value) => value!.isEmpty
                      ? 'Nama pelanggan tidak boleh kosong'
                      : null,
                ),
                TextFormField(
                  controller: alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: (value) =>
                      value!.isEmpty ? 'Alamat tidak boleh kosong' : null,
                ),
                TextFormField(
                  controller: teleponController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon tidak boleh kosong';
                    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Nomor telepon hanya boleh berisi angka';
                    }
                    return null;
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
                  final String nama = namaController.text;
                  final String alamat = alamatController.text;
                  final String nomorTelepon = teleponController.text;

                  final existingData = _pelanggan.any((p) =>
                      p['nama_pelanggan'] == nama &&
                      p['alamat'] == alamat &&
                      p['nomor_telepon'] == nomorTelepon);

                  if (existingData) {
                    Navigator.of(context)
                        .pop();
                    Future.delayed(Duration(milliseconds: 300), () {
                    _showError('Data pelanggan sudah ada!');
                    });
                    return;
                  }

                  if (pelanggan == null) {
                    await _supabase.from('pelanggan').insert({
                      'nama_pelanggan': nama,
                      'alamat': alamat,
                      'nomor_telepon': nomorTelepon,
                    });
                  } else {
                    await _supabase.from('pelanggan').update({
                      'nama_pelanggan': nama,
                      'alamat': alamat,
                      'nomor_telepon': nomorTelepon,
                    }).eq('id_pelanggan', pelanggan['id_pelanggan']);
                  }
                  Navigator.of(context).pop();
                  _fetchPelanggan();
                }
              },
              child: const Text('Simpan'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePelanggan(int id) async {
    try {
      await _supabase.from('pelanggan').delete().eq('id_pelanggan', id);
      _fetchPelanggan();
    } catch (e) {
      _showError('Gagal menghapus pelanggan: $e');
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content:
              const Text('Apakah Anda yakin ingin menghapus pelanggan ini?'),
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
                _deletePelanggan(id);
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
              style: TextButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 216, 18, 4),
                foregroundColor: Colors.white,
              ),
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
                labelText: 'Cari Pelanggan',
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
                    itemCount: _filteredPelanggan.length,
                    itemBuilder: (context, index) {
                      final pelanggan = _filteredPelanggan[index];
                      return Card(
                        child: ListTile(
                          title: Text(pelanggan['nama_pelanggan']),
                          subtitle: Text(
                              '${pelanggan['alamat']}\n${pelanggan['nomor_telepon']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xff16C47F)),
                                  onPressed: () => _addOrUpdatePelanggan(
                                      pelanggan: pelanggan)),
                              IconButton(
                                  icon: const Icon(Icons.delete, color: Color(0xffF93827)),
                                  onPressed: () => _confirmDelete(
                                      pelanggan['id_pelanggan'])),
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
        onPressed: () => _addOrUpdatePelanggan(),
        child: const Icon(Icons.add, color: Colors.white,),
        backgroundColor: Color(0xff16C47F),
      ),
      backgroundColor: Color(0xffEDF4C2),
    );
  }
}
