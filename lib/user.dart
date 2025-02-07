import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await _supabase.from('user').select();
      setState(() {
        _users = List<Map<String, dynamic>>.from(response as List<dynamic>);
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching users: $error');
    }
  }

  Future<void> _addUser(String username, String password) async {
    try {
      await _supabase.from('user').insert({'username': username, 'password': password});
      _fetchUsers();
    } catch (error) {
      debugPrint('Error adding user: $error');
    }
  }

  Future<void> _editUser(int id, String username, String password) async {
    try {
      await _supabase.from('user').update({'username': username, 'password': password}).eq('id', id);
      _fetchUsers();
    } catch (error) {
      debugPrint('Error editing user: $error');
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      await _supabase.from('user').delete().eq('id', id);
      _fetchUsers();
    } catch (error) {
      debugPrint('Error deleting user: $error');
    }
  }

  void _showDeleteConfirmation(int id) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penghapusan'),
        content: const Text('Apakah Anda yakin ingin menghapus user ini?'),
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
              _deleteUser(id);
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
  

  void _showUserDialog({Map<String, dynamic>? user}) {
    final TextEditingController usernameController = TextEditingController(text: user?['username'] ?? '');
    final TextEditingController passwordController = TextEditingController(text: user?['password'] ?? '');
    final _formKey = GlobalKey<FormState>();
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(user == null ? 'Tambah User' : 'Edit User'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) => value!.isEmpty ? 'Username tidak boleh kosong' : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureText = !obscureText),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Password tidak boleh kosong' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                  style: TextButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (user == null) {
                        _addUser(usernameController.text, passwordController.text);
                      } else {
                        _editUser(user['id'], usernameController.text, passwordController.text);
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(user == null ? 'Tambah' : 'Simpan'),
                  style: TextButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user['username']),
                  titleTextStyle: TextStyle(
                    fontSize: 20.0,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xff16C47F)),
                        onPressed: () => _showUserDialog(user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Color(0xffF93827)),
                        onPressed: () => _showDeleteConfirmation(user['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xff16C47F),
      ),
      backgroundColor: Color(0xffEDF4C2),
    );
  }
}
