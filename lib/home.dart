import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({Key? key}) : super(key: key);

  @override
  _RegistrasiPageState createState() => _RegistrasiPageState();
}

class _RegistrasiPageState extends State<RegistrasiPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
   int _currentIndex = 0;
  final PageController _pageController = PageController();
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

  Future<void> _addUser(String username, String password, String role) async {
    try {
      await _supabase.from('user').insert({
        'username': username,
        'password': password,
      });
      _fetchUsers();
    } catch (error) {
      debugPrint('Error adding user: $error');
    }
  }

  Future<void> _editUser(
      int id, String username, String password, String role) async {
    try {
      await _supabase.from('user').update({
        'username': username,
        'password': password,
      }).eq('id', id);
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
    final TextEditingController usernameController = TextEditingController(
      text: user != null ? user['username'] : '',
    );
    final TextEditingController passwordController = TextEditingController(
      text: user != null ? user['password'] : '',
    );

    String? selectedRole = user != null ? user['role'] : null;
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
                      validator: (value) =>
                          value!.isEmpty ? 'Username tidak boleh kosong' : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Password tidak boleh kosong' : null,
                    ),
                  ],
                ),
              ),
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
                    if (_formKey.currentState!.validate()) {
                      if (user == null) {
                        _addUser(usernameController.text,
                            passwordController.text, selectedRole!);
                      } else {
                        _editUser(user['id'], usernameController.text,
                            passwordController.text, selectedRole!);
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(user == null ? 'Tambah' : 'Simpan'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 33, 114, 243),
                    foregroundColor: Colors.white,
                  ),
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
      appBar: AppBar(
        title: const Text(
          'Registrasi User',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user['username']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                        ),
                        onPressed: () => _showUserDialog(user: user),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => _showDeleteConfirmation(user['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
             bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        backgroundColor: const Color.fromARGB(255, 7, 80, 190),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: _getBottomNavItems(),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: const Color.fromARGB(255, 7, 79, 186),
      ),
    );
  }
}

List<BottomNavigationBarItem> _getBottomNavItems() {
       {
        return const [
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'User',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Produk',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.account_balance_wallet),
          //   label: 'Pembayaran',
          // ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.history),
          //   label: 'Riwayat',
          // ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.people),
          //   label: 'Pelanggan',
          // ),
        ];
        }
     }

// ini error
// Handler: "onTap"
// Recognizer:
//   TapGestureRecognizer#116c2