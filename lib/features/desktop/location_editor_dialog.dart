part of 'desktop_shell_screen_v2.dart';

class LocationEditorDialog extends StatefulWidget {
  const LocationEditorDialog({
    super.key,
    required this.repository,
    this.location,
  });

  final InventoryRepository repository;
  final AllowedLocation? location;

  @override
  State<LocationEditorDialog> createState() => _LocationEditorDialogState();
}

class _LocationEditorDialogState extends State<LocationEditorDialog> {
  late final TextEditingController _codeController;
  late LocationType _type;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.location?.code ?? '');
    _type = widget.location?.type ?? LocationType.line;
    _isActive = widget.location?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final location = AllowedLocation(
      id: widget.location?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      code: _codeController.text.trim().toUpperCase(),
      type: _type,
      isActive: _isActive,
    );

    if (widget.location == null) {
      await widget.repository.addLocation(location);
    } else {
      await widget.repository.updateLocation(location);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? 'Add location' : 'Edit location'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DialogField(controller: _codeController, label: 'Location code'),
            const SizedBox(height: 10),
            DropdownButtonFormField<LocationType>(
              initialValue: _type,
              items: const <DropdownMenuItem<LocationType>>[
                DropdownMenuItem(value: LocationType.line, child: Text('Line')),
                DropdownMenuItem(value: LocationType.rack, child: Text('Rack')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _type = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Type'),
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
