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
  late final TextEditingController _serialController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _conditionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _manualUrlController;
  late final TextEditingController _notesController;
  late ItemStatus _status;
  String? _selectedCategory;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _qrController = TextEditingController(text: widget.item?.qrCode ?? widget.initialQrCode ?? '');
    _serialController = TextEditingController(text: widget.item?.serialNumber ?? '');
    _brandController = TextEditingController(text: widget.item?.brand ?? '');
    _modelController = TextEditingController(text: widget.item?.model ?? '');
    _conditionController = TextEditingController(text: widget.item?.condition ?? '');
    _imageUrlController = TextEditingController(text: widget.item?.imageUrl ?? '');
    _manualUrlController = TextEditingController(text: widget.item?.manualUrl ?? '');
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
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
    _serialController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _conditionController.dispose();
    _imageUrlController.dispose();
    _manualUrlController.dispose();
    _notesController.dispose();
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
      serialNumber: _optionalText(_serialController),
      brand: _optionalText(_brandController),
      model: _optionalText(_modelController),
      condition: _optionalText(_conditionController),
      imageUrl: _optionalText(_imageUrlController),
      manualUrl: _optionalText(_manualUrlController),
      notes: _optionalText(_notesController),
      expectedReturnAt: widget.item?.expectedReturnAt,
      createdAt: widget.item?.createdAt,
      updatedAt: DateTime.now(),
    );

    if (widget.item == null) {
      await widget.repository.addItem(item);
    } else {
      await widget.repository.updateItem(item);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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
    final categoryOptions = widget.categories
        .where((category) => category.isActive || category.name == _selectedCategory)
        .toList();
    final locationOptions = widget.locations
        .where((location) => location.isActive || location.code == _selectedLocation)
        .toList();
    return AlertDialog(
      title: Text(widget.item == null ? 'Register item' : 'Edit item'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: _DialogField(controller: _nameController, label: 'Item name')),
                  const SizedBox(width: 10),
                  Expanded(child: _DialogField(controller: _serialController, label: 'Serial number')),
                ],
              ),
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
              Row(
                children: <Widget>[
                  Expanded(child: _DialogField(controller: _brandController, label: 'Brand')),
                  const SizedBox(width: 10),
                  Expanded(child: _DialogField(controller: _modelController, label: 'Model')),
                  const SizedBox(width: 10),
                  Expanded(child: _DialogField(controller: _conditionController, label: 'Condition')),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: categoryOptions
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
                items: locationOptions
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Status'),
                      child: Text(
                        _status == ItemStatus.available ? 'Ready' : 'Borrowed',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _DialogField(controller: _imageUrlController, label: 'Photo URL')),
                ],
              ),
              const SizedBox(height: 10),
              _DialogField(controller: _manualUrlController, label: 'Manual or attachment URL'),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Maintenance notes',
                  hintText: 'Calibration, condition, repair history, or handling notes',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
