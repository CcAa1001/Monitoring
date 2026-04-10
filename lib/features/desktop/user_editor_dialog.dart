part of 'desktop_shell_screen_v2.dart';

class UserEditorDialog extends StatefulWidget {
  const UserEditorDialog({
    super.key,
    required this.repository,
    required this.roleOptions,
    this.user,
  });

  final InventoryRepository repository;
  final List<String> roleOptions;
  final AppUser? user;

  @override
  State<UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<UserEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _badgeController;
  late final TextEditingController _passwordController;
  late UserRole _role;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _badgeController = TextEditingController(text: widget.user?.badgeId ?? '');
    _passwordController = TextEditingController(text: widget.user?.password ?? '');
    _role = widget.user?.role ?? UserRole.operator;
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _badgeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = AppUser(
      id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      badgeId: _badgeController.text.trim().toUpperCase(),
      password: _passwordController.text,
      role: _role,
      isActive: _isActive,
    );

    if (widget.user == null) {
      await widget.repository.addUser(user);
    } else {
      await widget.repository.updateUser(user);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add user' : 'Edit user'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DialogField(controller: _nameController, label: 'Full name'),
            const SizedBox(height: 10),
            _DialogField(controller: _badgeController, label: 'Badge ID'),
            const SizedBox(height: 10),
            _DialogField(controller: _passwordController, label: 'Password'),
            const SizedBox(height: 10),
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              items: const <DropdownMenuItem<UserRole>>[
                DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                DropdownMenuItem(value: UserRole.operator, child: Text('Operator')),
                DropdownMenuItem(value: UserRole.viewer, child: Text('Viewer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _role = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    );
  }
}
