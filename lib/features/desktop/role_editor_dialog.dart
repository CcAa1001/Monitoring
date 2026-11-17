part of 'desktop_shell_screen_v2.dart';

class RoleEditorDialog extends StatefulWidget {
  const RoleEditorDialog({super.key});

  @override
  State<RoleEditorDialog> createState() => _RoleEditorDialogState();
}

class _RoleEditorDialogState extends State<RoleEditorDialog> {
  final TextEditingController _nameController = TextEditingController();
  final Map<String, bool> _permissions = <String, bool>{
    'Dasbor': true,
    'Peminjaman': false,
    'Pengembalian': false,
    'Riwayat': false,
    'Barang': false,
    'Kategori': false,
    'Lokasi': false,
    'Peran': false,
    'Pengguna': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final permissions = _permissions.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
    Navigator.of(context).pop(
      _RoleDefinition(
        name: name,
        permissions: permissions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah peran'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DialogField(controller: _nameController, label: 'Nama peran'),
            const SizedBox(height: 12),
            ..._permissions.keys.map(
              (permission) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(permission),
                value: _permissions[permission],
                onChanged: (value) {
                  setState(() {
                    _permissions[permission] = value ?? false;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
