part of 'desktop_shell_screen_v2.dart';

class UserSelfSettingsDialog extends StatefulWidget {
  const UserSelfSettingsDialog({
    super.key,
    required this.user,
  });

  final AppUser user;

  @override
  State<UserSelfSettingsDialog> createState() => _UserSelfSettingsDialogState();
}

class _UserSelfSettingsDialogState extends State<UserSelfSettingsDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _badgeController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _badgeController = TextEditingController(text: widget.user.badgeId);
    _passwordController = TextEditingController(text: widget.user.password);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _badgeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      widget.user.copyWith(
        name: _nameController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('User settings'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DialogField(controller: _nameController, label: 'Name'),
            const SizedBox(height: 10),
            TextField(
              controller: _badgeController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Badge ID'),
            ),
            const SizedBox(height: 10),
            _DialogField(controller: _passwordController, label: 'Password'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
