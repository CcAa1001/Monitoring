part of 'desktop_shell_screen_v2.dart';

class ItemEditorDialog extends StatefulWidget {
  const ItemEditorDialog({
    super.key,
    required this.repository,
    required this.categories,
    required this.locations,
    this.item,
    this.initialQrCode,
  });

  final InventoryRepository repository;
  final List<ItemCategory> categories;
  final List<AllowedLocation> locations;
  final Item? item;
  final String? initialQrCode;

  @override
  State<ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<ItemEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _qrController;
  late ItemStatus _status;
  String? _selectedCategory;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _qrController = TextEditingController(text: widget.item?.qrCode ?? widget.initialQrCode ?? '');
    _selectedCategory = widget.item?.category.isNotEmpty == true
        ? widget.item!.category
        : (widget.categories.isNotEmpty ? widget.categories.first.name : null);
    _selectedLocation = widget.item?.currentLocation.isNotEmpty == true
        ? widget.item!.currentLocation
        : (widget.locations.isNotEmpty ? widget.locations.first.code : null);
    _status = widget.item?.status ?? _deriveStatus(_selectedLocation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final qrCode = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const ScanScreen(),
      ),
    );

    if (qrCode == null || !mounted) return;
    setState(() {
      _qrController.text = qrCode;
    });
  }

  Future<void> _save() async {
    final derivedStatus = _deriveStatus(_selectedLocation);
    final item = Item(
      id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      qrCode: _qrController.text.trim(),
      name: _nameController.text.trim(),
      category: _selectedCategory ?? '',
      currentLocation: _selectedLocation ?? '',
      status: derivedStatus,
      lastBorrowerName: widget.item?.lastBorrowerName,
    );

    if (widget.item == null) {
      await widget.repository.addItem(item);
    } else {
      await widget.repository.updateItem(item);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  ItemStatus _deriveStatus(String? locationCode) {
    final location = widget.locations.cast<AllowedLocation?>().firstWhere(
          (entry) => entry?.code == locationCode,
          orElse: () => null,
        );
    if (location?.type == LocationType.line) {
      return ItemStatus.borrowed;
    }
    return ItemStatus.available;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Register item' : 'Edit item'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DialogField(controller: _nameController, label: 'Item name'),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(child: _DialogField(controller: _qrController, label: 'QR code')),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _scanQrCode,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: widget.categories
                  .where((category) => category.isActive)
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category.name,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocation,
              items: widget.locations
                  .where((location) => location.isActive)
                  .map(
                    (location) => DropdownMenuItem<String>(
                      value: location.code,
                      child: Text(location.code),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value;
                  _status = _deriveStatus(value);
                });
              },
              decoration: const InputDecoration(labelText: 'Current location'),
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Status'),
              child: Text(
                _status == ItemStatus.available ? 'Ready' : 'Borrowed',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
