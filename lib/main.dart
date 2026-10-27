import 'package:flutter/material.dart';

import 'models/user_model.dart';
import 'pages/user_form_page.dart';
import 'services/user_service.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  title: 'ReqRes CRUD',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
  home: const UserListPage(),
);
  }
}

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final _service = UserService();
  late Future<List<UserModel>> _future;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UserModel>> _load() async {
    final result = await _service.getUsers();
    _users = result;
    return result;
  }

  void _reload() => setState(() => _future = _load());

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: error ? Colors.red : null),
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => const UserFormPage()),
    );
    if (created != null) {
      // reqres tidak menyimpan data sungguhan, jadi ditambahkan ke list lokal
      setState(() => _users = [created, ..._users]);
      _showMessage('User "${created.fullName}" berhasil dibuat (ID: ${created.id})');
    }
  }

  Future<void> _openEdit(UserModel user) async {
    final updated = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(builder: (_) => UserFormPage(user: user)),
    );
    if (updated != null) {
      setState(() {
        _users = _users.map((u) => u.id == updated.id ? updated : u).toList();
      });
      _showMessage('User "${updated.fullName}" berhasil diperbarui');
    }
  }

  Future<void> _delete(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus user?'),
        content: Text('Hapus ${user.fullName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteUser(user.id);
      setState(() => _users = _users.where((u) => u.id != user.id).toList());
      _showMessage('User "${user.fullName}" berhasil dihapus');
    } on ApiException catch (e) {
      _showMessage(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar User'),
        actions: [
          IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: _reload, child: const Text('Coba lagi')),
                  ],
                ),
              ),
            );
          }
          if (_users.isEmpty) {
            return const Center(child: Text('Belum ada data user.'));
          }
          return ListView.separated(
            itemCount: _users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final u = _users[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      u.avatar.isNotEmpty ? NetworkImage(u.avatar) : null,
                  child: u.avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(u.fullName),
                subtitle: Text(u.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openEdit(u)),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(u)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}